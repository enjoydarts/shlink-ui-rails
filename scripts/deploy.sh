#!/bin/bash
# 本番デプロイ用スクリプト
# GitHub Actionsから呼び出される本番デプロイスクリプト
#
# 使用方法:
#   ./scripts/deploy.sh
#
# 環境変数:
#   - IMAGE: デプロイするDockerイメージ
#   - DIGEST: イメージのダイジェスト
#
# 機能:
#   - ゼロダウンタイムデプロイ
#   - 自動ロールバック
#   - ヘルスチェック
#   - バックアップ作成

set -euo pipefail

# 設定
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly APP_DIR="/opt/shlink-ui-rails"
readonly LOG_FILE="$APP_DIR/logs/deploy.log"
readonly HEALTH_CHECK_TIMEOUT=300  # 5分
readonly BACKUP_RETENTION_DAYS=7
readonly MAX_ROLLBACK_ATTEMPTS=3

# カラー定義
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ログ関数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")  printf "[%s] ${BLUE}INFO${NC}:  %s\n" "$timestamp" "$message" ;;
        "WARN")  printf "[%s] ${YELLOW}WARN${NC}:  %s\n" "$timestamp" "$message" ;;
        "ERROR") printf "[%s] ${RED}ERROR${NC}: %s\n" "$timestamp" "$message" ;;
        "SUCCESS") printf "[%s] ${GREEN}SUCCESS${NC}: %s\n" "$timestamp" "$message" ;;
    esac

    # ファイルにも出力
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# エラーハンドリング
handle_error() {
    local exit_code=$?
    local line_number=$1
    log "ERROR" "Deployment failed at line $line_number (exit code: $exit_code)"

    # 緊急時はロールバックを実行
    if [[ ${ROLLBACK_ON_ERROR:-true} == "true" ]]; then
        log "WARN" "Attempting emergency rollback..."
        emergency_rollback
    fi

    exit $exit_code
}

trap 'handle_error $LINENO' ERR

# 前提条件チェック
check_prerequisites() {
    log "INFO" "Checking prerequisites..."

    # 必要なコマンドの存在確認
    local required_commands=("docker" "docker-compose" "curl" "git")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "ERROR" "Required command not found: $cmd"
            exit 1
        fi
    done

    # ディレクトリ存在確認
    if [[ ! -d "$APP_DIR" ]]; then
        log "ERROR" "Application directory not found: $APP_DIR"
        exit 1
    fi

    # 環境変数ファイル確認
    if [[ ! -f "$APP_DIR/.env.production" ]]; then
        log "ERROR" "Production environment file not found: $APP_DIR/.env.production"
        exit 1
    fi

    # Docker compose ファイル確認
    if [[ ! -f "$APP_DIR/docker-compose.prod.yml" ]]; then
        log "ERROR" "Production docker-compose file not found"
        exit 1
    fi

    log "SUCCESS" "All prerequisites satisfied"
}

# アプリケーションのヘルスチェック
health_check() {
    local endpoint="$1"
    local timeout="${2:-30}"
    local max_attempts=3

    log "INFO" "Running health check: $endpoint"

    for attempt in $(seq 1 $max_attempts); do
        if curl -sf --max-time "$timeout" "$endpoint" >/dev/null 2>&1; then
            log "SUCCESS" "Health check passed (attempt $attempt/$max_attempts)"
            return 0
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            log "WARN" "Health check failed (attempt $attempt/$max_attempts), retrying..."
            sleep 10
        fi
    done

    log "ERROR" "Health check failed after $max_attempts attempts"
    return 1
}

# 現在のコンテナをバックアップ
create_backup() {
    log "INFO" "Creating backup of current deployment..."

    local backup_tag="backup-$(date +%Y%m%d-%H%M%S)"

    if docker-compose -f "$APP_DIR/docker-compose.prod.yml" ps -q app >/dev/null 2>&1; then
        local running_container
        running_container=$(docker-compose -f "$APP_DIR/docker-compose.prod.yml" ps -q app)

        if [[ -n "$running_container" ]]; then
            if docker commit "$running_container" "shlink-ui-rails:$backup_tag"; then
                echo "$backup_tag" > "$APP_DIR/.last_backup_tag"
                log "SUCCESS" "Backup created: $backup_tag"
                return 0
            else
                log "WARN" "Failed to create backup"
                return 1
            fi
        fi
    fi

    log "INFO" "No running container to backup"
    return 0
}

# データベースマイグレーション
run_migrations() {
    log "INFO" "Checking for database migrations..."

    # まずマイグレーションステータスをチェック
    if docker-compose -f "$APP_DIR/docker-compose.prod.yml" run --rm app rails db:migrate:status | grep -q "down"; then
        log "INFO" "Running database migrations..."

        # バックアップ前にマイグレーションを実行
        if ! docker-compose -f "$APP_DIR/docker-compose.prod.yml" run --rm app rails db:migrate; then
            log "ERROR" "Database migration failed"
            return 1
        fi

        log "SUCCESS" "Database migrations completed"
    else
        log "INFO" "No new migrations to run"
    fi

    return 0
}

# システム設定初期化
initialize_system_settings() {
    log "INFO" "Initializing system settings..."

    if docker-compose -f "$APP_DIR/docker-compose.prod.yml" run --rm app rails runner "SystemSetting.initialize_defaults!"; then
        log "SUCCESS" "System settings initialized"
        return 0
    else
        log "ERROR" "Failed to initialize system settings"
        return 1
    fi
}

# サービス再起動（ゼロダウンタイム）
restart_services() {
    log "INFO" "Restarting services with zero-downtime strategy..."

    # 新しいコンテナを起動（既存と並行実行）
    if ! docker-compose -f "$APP_DIR/docker-compose.prod.yml" up -d --force-recreate; then
        log "ERROR" "Failed to restart services"
        return 1
    fi

    log "SUCCESS" "Services restarted"
    return 0
}

# ヘルスチェック待機
wait_for_health() {
    log "INFO" "Waiting for application to be healthy..."

    local start_time=$(date +%s)
    local timeout_time=$((start_time + HEALTH_CHECK_TIMEOUT))

    while [[ $(date +%s) -lt $timeout_time ]]; do
        if health_check "http://localhost:3000/health" 10; then
            local elapsed=$(($(date +%s) - start_time))
            log "SUCCESS" "Application is healthy (took ${elapsed}s)"
            return 0
        fi

        log "INFO" "Waiting for health check..."
        sleep 10
    done

    log "ERROR" "Health check timeout after ${HEALTH_CHECK_TIMEOUT}s"
    return 1
}

# 緊急ロールバック
emergency_rollback() {
    log "WARN" "Initiating emergency rollback..."

    if [[ -f "$APP_DIR/.last_backup_tag" ]]; then
        local backup_tag
        backup_tag=$(cat "$APP_DIR/.last_backup_tag")

        if docker image inspect "shlink-ui-rails:$backup_tag" >/dev/null 2>&1; then
            log "INFO" "Rolling back to: $backup_tag"

            # バックアップイメージをlatestとしてタグ
            docker tag "shlink-ui-rails:$backup_tag" "shlink-ui-rails:latest"

            # サービス再起動
            docker-compose -f "$APP_DIR/docker-compose.prod.yml" up -d --force-recreate

            # ヘルスチェック
            sleep 30
            if health_check "http://localhost:3000/health" 30; then
                log "SUCCESS" "Emergency rollback successful"
                return 0
            else
                log "ERROR" "Emergency rollback failed"
                return 1
            fi
        else
            log "ERROR" "Backup image not found: $backup_tag"
        fi
    else
        log "ERROR" "No backup available for rollback"
    fi

    return 1
}

# 古いバックアップのクリーンアップ
cleanup_old_backups() {
    log "INFO" "Cleaning up old backups..."

    # 古いバックアップイメージを削除
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" | \
        grep "backup-" | \
        awk -v date="$(date -d "$BACKUP_RETENTION_DAYS days ago" +%Y-%m-%d)" '$2 < date {print $1}' | \
        xargs -r docker rmi 2>/dev/null || true

    # 使用されていないイメージをクリーンアップ
    docker system prune -f --filter "until=24h" >/dev/null 2>&1 || true

    log "SUCCESS" "Cleanup completed"
}

# メイン処理
main() {
    log "INFO" "Starting deployment process..."
    log "INFO" "Image: ${IMAGE:-latest}"
    log "INFO" "Digest: ${DIGEST:-unknown}"

    # 前提条件チェック
    check_prerequisites

    # アプリケーションディレクトリに移動
    cd "$APP_DIR"

    # サーバーローカルのソースコードを最新に更新
    log "INFO" "Updating local source code..."
    git fetch origin
    git reset --hard origin/main

    log "SUCCESS" "Local source code updated to latest commit"

    # 現在の状態をバックアップ
    create_backup

    # GitHub Container Registryにログイン（環境変数から）
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        log "INFO" "Logging into GitHub Container Registry..."
        echo "$GITHUB_TOKEN" | docker login ghcr.io -u "${GITHUB_ACTOR:-github-actions}" --password-stdin
    fi

    # 最新のDockerイメージをプル
    log "INFO" "Pulling Docker image: ${IMAGE:-latest}"
    if ! docker-compose -f docker-compose.prod.yml pull; then
        log "ERROR" "Failed to pull Docker image"
        exit 1
    fi

    # データベースマイグレーション
    run_migrations

    # システム設定初期化
    initialize_system_settings

    # サービス再起動
    restart_services

    # ヘルスチェック
    if ! wait_for_health; then
        log "ERROR" "Deployment failed - health check failed"
        emergency_rollback
        exit 1
    fi

    # クリーンアップ
    cleanup_old_backups

    # デプロイ成功ログ
    local commit_hash=""
    if [[ -d "app" ]]; then
        commit_hash=$(git -C app rev-parse --short HEAD 2>/dev/null || echo "unknown")
    fi

    log "SUCCESS" "Deployment completed successfully!"
    log "INFO" "Commit: $commit_hash"
    log "INFO" "Image: ${IMAGE:-latest}"
    log "INFO" "Digest: ${DIGEST:-unknown}"

    # 成功をファイルに記録
    echo "$(date): Deployment completed successfully - $commit_hash" >> "$APP_DIR/deploy.log"
}

# スクリプト実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi