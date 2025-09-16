#!/bin/bash
# 本番環境ロールバックスクリプト
# デプロイに問題が発生した場合の緊急ロールバック用
#
# 使用方法:
#   ./scripts/rollback.sh [backup-tag]
#
# 例:
#   ./scripts/rollback.sh backup-20240316-143022
#   ./scripts/rollback.sh  # 最新のバックアップを使用

set -euo pipefail

# 設定
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly APP_DIR="/opt/shlink-ui-rails"
readonly LOG_FILE="$APP_DIR/logs/rollback.log"
readonly HEALTH_CHECK_TIMEOUT=300

# カラー定義
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

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

    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# エラーハンドリング
handle_error() {
    local exit_code=$?
    local line_number=$1
    log "ERROR" "Rollback failed at line $line_number (exit code: $exit_code)"
    exit $exit_code
}

trap 'handle_error $LINENO' ERR

# 利用可能なバックアップ一覧を表示
list_backups() {
    log "INFO" "Available backups:"
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" | \
        grep -E "shlink-ui-rails:backup-" | \
        sort -k2 -r || {
        log "WARN" "No backup images found"
        return 1
    }
}

# バックアップタグの検証
validate_backup() {
    local backup_tag="$1"

    if ! docker image inspect "shlink-ui-rails:$backup_tag" >/dev/null 2>&1; then
        log "ERROR" "Backup image not found: $backup_tag"
        return 1
    fi

    log "INFO" "Backup image validated: $backup_tag"
    return 0
}

# ヘルスチェック
health_check() {
    local endpoint="$1"
    local timeout="${2:-30}"

    if curl -sf --max-time "$timeout" "$endpoint" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
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

# データベースバックアップ
backup_database() {
    log "INFO" "Creating database backup before rollback..."

    local backup_file="$APP_DIR/backups/pre_rollback_$(date +%Y%m%d_%H%M%S).sql.gz"

    if docker-compose -f "$APP_DIR/docker-compose.prod.yml" exec -T app rails db:dump | gzip > "$backup_file"; then
        log "SUCCESS" "Database backup created: $backup_file"
        return 0
    else
        log "ERROR" "Failed to create database backup"
        return 1
    fi
}

# 現在の状態をスナップショット
create_pre_rollback_snapshot() {
    log "INFO" "Creating pre-rollback snapshot..."

    local snapshot_tag="pre-rollback-$(date +%Y%m%d-%H%M%S)"

    if docker-compose -f "$APP_DIR/docker-compose.prod.yml" ps -q app >/dev/null 2>&1; then
        local running_container
        running_container=$(docker-compose -f "$APP_DIR/docker-compose.prod.yml" ps -q app)

        if [[ -n "$running_container" ]]; then
            if docker commit "$running_container" "shlink-ui-rails:$snapshot_tag"; then
                echo "$snapshot_tag" > "$APP_DIR/.pre_rollback_snapshot"
                log "SUCCESS" "Pre-rollback snapshot created: $snapshot_tag"
            else
                log "WARN" "Failed to create pre-rollback snapshot"
            fi
        fi
    fi
}

# ロールバック実行
perform_rollback() {
    local backup_tag="$1"

    log "INFO" "Starting rollback to: $backup_tag"

    # 現在の状態をスナップショット
    create_pre_rollback_snapshot

    # データベースバックアップ（オプション）
    if [[ "${BACKUP_DB:-true}" == "true" ]]; then
        backup_database || log "WARN" "Database backup failed, continuing..."
    fi

    # バックアップイメージをlatestとしてタグ
    log "INFO" "Tagging backup image as latest..."
    if ! docker tag "shlink-ui-rails:$backup_tag" "shlink-ui-rails:latest"; then
        log "ERROR" "Failed to tag backup image"
        return 1
    fi

    # サービス停止
    log "INFO" "Stopping current services..."
    docker-compose -f "$APP_DIR/docker-compose.prod.yml" down || log "WARN" "Failed to stop services gracefully"

    # サービス再起動
    log "INFO" "Starting services with rollback image..."
    if ! docker-compose -f "$APP_DIR/docker-compose.prod.yml" up -d; then
        log "ERROR" "Failed to start services with rollback image"
        return 1
    fi

    # ヘルスチェック
    if wait_for_health; then
        log "SUCCESS" "Rollback completed successfully!"
        echo "$backup_tag" > "$APP_DIR/.last_rollback_tag"
        echo "$(date): Rollback completed successfully - $backup_tag" >> "$APP_DIR/rollback.log"
        return 0
    else
        log "ERROR" "Rollback health check failed"
        return 1
    fi
}

# 使用方法表示
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [BACKUP_TAG]

Options:
    -l, --list          List available backups
    -h, --help          Show this help message
    --no-db-backup      Skip database backup before rollback
    --dry-run          Show what would be done without executing

Examples:
    $0 -l                                  # List available backups
    $0 backup-20240316-143022              # Rollback to specific backup
    $0                                     # Rollback to latest backup
    $0 --dry-run backup-20240316-143022    # Show what would be done

EOF
}

# メイン処理
main() {
    local backup_tag=""
    local dry_run=false
    local list_only=false

    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            -l|--list)
                list_only=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --no-db-backup)
                export BACKUP_DB=false
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            backup-*)
                backup_tag="$1"
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # バックアップ一覧表示のみ
    if [[ "$list_only" == "true" ]]; then
        list_backups
        exit 0
    fi

    # バックアップタグが指定されていない場合は最新を使用
    if [[ -z "$backup_tag" ]]; then
        log "INFO" "No backup tag specified, finding latest backup..."
        if [[ -f "$APP_DIR/.last_backup_tag" ]]; then
            backup_tag=$(cat "$APP_DIR/.last_backup_tag")
            log "INFO" "Using latest backup: $backup_tag"
        else
            log "ERROR" "No backup tag specified and no last backup found"
            log "INFO" "Use -l to list available backups"
            exit 1
        fi
    fi

    # バックアップの存在確認
    if ! validate_backup "$backup_tag"; then
        log "ERROR" "Invalid backup tag: $backup_tag"
        list_backups
        exit 1
    fi

    # Dry runモード
    if [[ "$dry_run" == "true" ]]; then
        log "INFO" "DRY RUN MODE - No changes will be made"
        log "INFO" "Would rollback to: $backup_tag"
        log "INFO" "Would create pre-rollback snapshot"
        if [[ "${BACKUP_DB:-true}" == "true" ]]; then
            log "INFO" "Would create database backup"
        fi
        log "INFO" "Would restart services with rollback image"
        log "INFO" "Would perform health check"
        exit 0
    fi

    # 確認プロンプト
    log "WARN" "Are you sure you want to rollback to: $backup_tag?"
    read -p "Type 'yes' to confirm: " confirm
    if [[ "$confirm" != "yes" ]]; then
        log "INFO" "Rollback cancelled"
        exit 0
    fi

    # アプリケーションディレクトリに移動
    cd "$APP_DIR"

    # ロールバック実行
    log "INFO" "Starting rollback process..."
    if perform_rollback "$backup_tag"; then
        log "SUCCESS" "Rollback completed successfully!"
        log "INFO" "Application should be accessible at: https://app.kty.at"
        log "INFO" "Please verify the application is working correctly"
    else
        log "ERROR" "Rollback failed!"
        exit 1
    fi
}

# スクリプト実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi