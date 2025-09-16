#!/bin/bash

# 本番環境デプロイスクリプト
set -e

echo "🚀 Starting production deployment..."

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

# サービスを起動
echo "▶️ Starting services..."
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