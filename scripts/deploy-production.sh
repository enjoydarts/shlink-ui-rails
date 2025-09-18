#!/bin/bash

# 本番環境デプロイスクリプト
set -e

echo "🚀 Starting production deployment..."

# 通知関数
send_notification() {
    local status="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')
    local git_commit="${GIT_COMMIT:-unknown}"

    if [ "$status" = "success" ]; then
        local emoji="🚀"
        local title="デプロイ完了"
        local color="3066993"  # 緑色
    else
        local emoji="🚨"
        local title="デプロイ失敗"
        local color="15158332"  # 赤色
    fi

    local full_message="$emoji **$title**
**プロジェクト:** Shlink-UI-Rails
**環境:** Production
**コミット:** \`$git_commit\`
**時刻:** $timestamp

$message"

    # Discord通知
    if [ -n "$DISCORD_WEBHOOK_URL" ]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"embeds\":[{\"title\":\"$title\",\"description\":\"$full_message\",\"color\":$color}]}" \
             "$DISCORD_WEBHOOK_URL" 2>/dev/null || true
    fi

    # Slack通知
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"text\":\"$full_message\"}" \
             "$SLACK_WEBHOOK_URL" 2>/dev/null || true
    fi

    # システムログに記録
    logger -t shlink-ui-rails-deploy "$full_message"
}

# エラー時の通知
trap 'send_notification "failure" "デプロイが失敗しました。\n\n**エラー:** Line $LINENO (exit code: $?)"' ERR

# プロジェクトディレクトリに移動
cd "$(dirname "$0")/.."

# 環境変数ファイルの存在確認
if [ ! -f .env.production ]; then
    echo "❌ Error: .env.production file not found"
    exit 1
fi

# Docker Composeで既存のサービスを停止
echo "🛑 Stopping existing services..."
docker-compose -f docker-compose.prod.yml down --remove-orphans

# 古いコンテナをクリーンアップ
echo "🧹 Cleaning up old containers..."
docker container prune -f

# イメージをビルド
echo "🔨 Building Docker images..."
docker-compose -f docker-compose.prod.yml build --no-cache

# 環境変数を設定してサービスを起動
echo "▶️ Starting services..."
export GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
export BUILD_TIME=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
echo "📅 Git commit: $GIT_COMMIT"
echo "📅 Build time: $BUILD_TIME"
docker-compose -f docker-compose.prod.yml up -d

# ヘルスチェック待機
echo "⏳ Waiting for services to be healthy..."
sleep 30

# サービス状態確認
echo "📊 Checking service status..."
docker-compose -f docker-compose.prod.yml ps

# ログの最初の部分を表示
echo "📝 Recent logs:"
echo "--- App logs ---"
docker logs shlink-ui-rails-app --tail 10
echo "--- Jobs logs ---"
docker logs shlink-ui-rails-jobs --tail 10

echo "✅ Deployment completed successfully!"
echo "🌐 Application is available at: http://localhost:3000"

# 成功通知を送信
send_notification "success" "デプロイが正常に完了しました。\n\n**URL:** http://localhost:3000"