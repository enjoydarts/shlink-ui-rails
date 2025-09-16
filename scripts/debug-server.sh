#!/bin/bash
# サーバー側での状況確認用デバッグスクリプト

set -e

echo "=== Shlink-UI-Rails サーバー状況確認 ==="
echo "実行日時: $(date)"
echo

# 基本情報
echo "📍 現在地："
pwd
echo

# Docker Compose状況
echo "🐳 Docker Compose サービス状況："
docker-compose -f docker-compose.prod.yml ps
echo

# 実行中のイメージ
echo "🖼️  使用中のDockerイメージ："
docker images | grep shlink-ui-rails | head -5
echo

# コンテナログ（最新20行）
echo "📋 アプリケーションログ（最新20行）："
docker-compose -f docker-compose.prod.yml logs app --tail=20
echo

# 環境変数確認
echo "🔧 環境変数："
docker-compose -f docker-compose.prod.yml exec -T app env | grep -E "(RAILS_ENV|GIT_COMMIT|APP_HOST)" || echo "環境変数が見つかりません"
echo

# Railsルート確認
echo "🛣️  Railsルート（version関連）："
docker-compose -f docker-compose.prod.yml exec -T app bundle exec rails routes | grep -i version || echo "versionルートが見つかりません"
echo

# ファイル存在確認
echo "📁 重要ファイルの存在確認："
docker-compose -f docker-compose.prod.yml exec -T app ls -la config/routes.rb app/controllers/pages_controller.rb || echo "ファイル確認失敗"
echo

# 内部ヘルスチェック
echo "🏥 内部ヘルスチェック："
curl -sf http://localhost:3000/health && echo "✅ OK" || echo "❌ 失敗"
echo

# バージョンエンドポイント確認
echo "📊 バージョンエンドポイント："
curl -sf http://localhost:3000/version && echo || echo "❌ /version エンドポイント失敗"
echo

echo "=== 確認完了 ==="