# 📊 監視・アラートガイド

このガイドでは、Shlink-UI-Rails本番デプロイメントの監視、アラート、通知システムについて説明します。

## 🎯 概要

監視システムは、アプリケーションのヘルス、パフォーマンスメトリクス、重要な問題に対する自動アラートの包括的な可視性を提供します。

## 📈 ヘルス監視

### アプリケーションヘルスエンドポイント

アプリケーションは複数のヘルスチェックエンドポイントを提供します：

```bash
# メインヘルスチェック
GET /health
レスポンス: {"status": "ok", "timestamp": "2024-01-01T00:00:00Z"}

# データベースヘルス
GET /health/database
レスポンス: {"status": "ok", "connection": "active", "query_time": "0.002s"}

# Redisヘルス
GET /health/redis
レスポンス: {"status": "ok", "connection": "active", "ping_time": "0.001s"}

# Shlink APIヘルス
GET /health/shlink
レスポンス: {"status": "ok", "api_version": "3.0.0", "response_time": "0.150s"}
```

### システム監視

#### リソース監視
```bash
# CPUとメモリ使用量
docker stats --no-stream

# ディスク使用量
df -h

# アプリケーションリソース制限
docker exec app sh -c 'echo "Memory: $(cat /proc/meminfo | grep MemAvailable)"; echo "CPU: $(nproc) cores"'
```

#### ログ監視
```bash
# アプリケーションログ
tail -f logs/production.log

# コンテナログ
docker-compose logs -f app

# システムログ
journalctl -f -u docker
```

## 🚨 デプロイメント通知

### 対応している通知チャンネル

#### 1. Slack通知
Webhook URLを使用してSlackチャンネルに通知を送信。

**設定**:
```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
```

**メッセージ形式**:
```json
{
  "text": "🚀 **デプロイ完了**",
  "attachments": [
    {
      "color": "good",
      "fields": [
        {"title": "プロジェクト", "value": "Shlink-UI-Rails", "short": true},
        {"title": "環境", "value": "Production (app.kty.at)", "short": true},
        {"title": "コミット", "value": "abc1234", "short": true},
        {"title": "イメージ", "value": "ghcr.io/enjoydarts/shlink-ui-rails:latest", "short": true}
      ],
      "footer": "デプロイシステム",
      "ts": 1640995200
    }
  ]
}
```

#### 2. Discord通知
Webhook URLを使用してDiscordチャンネルに通知を送信。

**設定**:
```bash
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK"
```

**メッセージ形式**:
```json
{
  "embeds": [
    {
      "title": "🚀 デプロイ完了",
      "color": 3066993,
      "fields": [
        {"name": "プロジェクト", "value": "Shlink-UI-Rails", "inline": true},
        {"name": "環境", "value": "Production (app.kty.at)", "inline": true},
        {"name": "コミット", "value": "`abc1234`", "inline": true},
        {"name": "イメージ", "value": "ghcr.io/enjoydarts/shlink-ui-rails:latest", "inline": false}
      ],
      "timestamp": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

#### 3. メール通知
設定されたメールシステムを使用してメール通知を送信。

**設定**:
```bash
export NOTIFICATION_EMAIL="admin@example.com"
```

### 通知内容

#### 成功通知
```
🚀 **デプロイ完了**
**プロジェクト:** Shlink-UI-Rails
**環境:** Production (app.kty.at)
**コミット:** `abc1234` - 機能更新
**イメージ:** `ghcr.io/enjoydarts/shlink-ui-rails:latest`
**所要時間:** 2分34秒
**ヘルスチェック:** ✅ 成功
**時刻:** 2024-01-01 14:30:00 JST
```

#### 失敗通知
```
🚨 **デプロイ失敗**
**プロジェクト:** Shlink-UI-Rails
**環境:** Production (app.kty.at)
**コミット:** `abc1234` - 機能更新
**イメージ:** `ghcr.io/enjoydarts/shlink-ui-rails:latest`
**所要時間:** 1分45秒
**失敗段階:** ヘルスチェック
**エラー:** 10回試行後もヘルスチェックが失敗 (HTTP 500)
**時刻:** 2024-01-01 14:30:00 JST

**次のステップ:**
- アプリケーションログを確認: `docker-compose logs app`
- データベース接続を検証
- 最近の変更をレビュー
```

#### ロールバック通知
```
🔄 **自動ロールバック完了**
**プロジェクト:** Shlink-UI-Rails
**環境:** Production (app.kty.at)
**失敗コミット:** `abc1234`
**復旧コミット:** `def5678`
**ロールバック時間:** 45秒
**状態:** ✅ サービス復旧
**時刻:** 2024-01-01 14:35:00 JST
```

## ⚙️ 設定

### GitHub Secretsの設定（推奨）

GitHubリポジトリ設定で以下のシークレットを追加:

1. GitHub Repository → Settings → Secrets and variables → Actions
2. 以下のシークレットを追加:

| シークレット名 | 説明 | 例 |
|--------------|------|---|
| `SLACK_WEBHOOK_URL` | SlackのwebhookURL | `https://hooks.slack.com/services/...` |
| `DISCORD_WEBHOOK_URL` | DiscordのwebhookURL | `https://discord.com/api/webhooks/...` |
| `NOTIFICATION_EMAIL` | 管理者メールアドレス | `admin@yourdomain.com` |

### サーバー側設定（オプション）

手動デプロイまたはサーバー側設定の場合、`.env.production`に追加:

```bash
# デプロイ通知設定
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK
NOTIFICATION_EMAIL=admin@example.com
```

**優先度**: GitHub Secretsが`.env.production`設定より優先されます。

## 🔧 Webhook設定

### Slack Webhook設定
1. Slackワークスペース設定に移動
2. Apps → Incoming Webhooksに移動
3. 目的のチャンネルで新しいwebhookを作成
4. Webhook URLをコピー

### Discord Webhook設定
1. Discordサーバーに移動
2. チャンネル設定 → 連携サービス → ウェブフックに移動
3. 新しいwebhookを作成
4. Webhook URLをコピー

## 📊 アプリケーションメトリクス

### パフォーマンスメトリクス
```bash
# レスポンス時間監視
curl -w "@curl-format.txt" -o /dev/null -s https://yourdomain.com/health

# データベースクエリパフォーマンス
docker exec app rails runner "
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  puts '上記にデータベースクエリがログ出力されました'
"

# キャッシュヒット率
docker exec app rails runner "puts Rails.cache.stats"
```

### カスタムメトリクス収集
```ruby
# Railsアプリケーション内で
class MetricsCollector
  def self.collect_deployment_metrics
    {
      timestamp: Time.current.iso8601,
      response_time: measure_response_time,
      database_connections: ActiveRecord::Base.connection_pool.stat,
      memory_usage: `ps -o pid,ppid,pmem,rss,vsz,args -p #{Process.pid}`.split("\n")[1],
      cache_stats: Rails.cache.stats
    }
  end

  private

  def self.measure_response_time
    start_time = Time.current
    Net::HTTP.get_response(URI('http://localhost:3000/health'))
    ((Time.current - start_time) * 1000).round(2)
  end
end
```

## 🔍 ログ分析

### 構造化ログ
```ruby
# Railsアプリケーション内で
Rails.logger.info({
  event: 'deployment_completed',
  commit_sha: ENV['GITHUB_SHA'],
  timestamp: Time.current.iso8601,
  metrics: {
    response_time: 150,
    memory_usage: '256MB',
    cpu_usage: '12%'
  }
}.to_json)
```

### ログ集約
```bash
# journalctlでの一元化ログ
journalctl -t shlink-ui-rails-deploy -f --output=json

# アプリケーション固有ログ
tail -f logs/production.log | jq '.level, .message, .timestamp'

# エラー追跡
grep -i error logs/production.log | tail -20
```

## 🚨 アラートルール

### 重要なアラート
- アプリケーションヘルスチェック失敗（連続3回以上の失敗）
- デプロイメント失敗
- データベース接続失敗
- 高いエラー率（リクエストの>5%）
- メモリ使用量>90%
- ディスク使用量>85%

### 警告アラート
- レスポンス時間>2秒
- メモリ使用量>70%
- ディスク使用量>70%
- キューのバックアップ（保留中ジョブ>100件）

### アラートエスカレーション
```bash
# 初回アラート: Slack/Discord通知
# 2回目アラート（15分後）: メール通知
# 3回目アラート（30分後）: SMS/電話通知（設定されている場合）
```

## 🛠️ カスタム監視設定

### 外部監視サービス

#### UptimeRobot設定
```bash
# 監視URL
https://yourdomain.com/health（5分間隔）
https://yourdomain.com/（5分間隔）

# アラート連絡先
- メール: admin@yourdomain.com
- Slack: webhook連携
- SMS: +1-555-0123（重要なアラート用）
```

#### Pingdom設定
```bash
# HTTPチェック
URL: https://yourdomain.com/health
間隔: 1分
タイムアウト: 10秒
期待レスポンス: 200 OK
コンテンツチェック: "status":"ok"
```

### セルフホスト監視

#### Grafana + Prometheus設定
```yaml
# docker-compose.monitoring.yml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-storage:/var/lib/grafana

volumes:
  grafana-storage:
```

## 🔗 統合例

### Webhookテスト
```bash
# Slack webhookテスト
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Shlink-UI-Railsからのテスト通知"}' \
  YOUR_SLACK_WEBHOOK_URL

# Discord webhookテスト
curl -X POST -H 'Content-type: application/json' \
  --data '{"content":"Shlink-UI-Railsからのテスト通知"}' \
  YOUR_DISCORD_WEBHOOK_URL
```

### カスタム通知スクリプト
```bash
#!/bin/bash
# scripts/notify.sh

MESSAGE="$1"
WEBHOOK_URL="$SLACK_WEBHOOK_URL"

if [ -n "$WEBHOOK_URL" ]; then
  curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"$MESSAGE\"}" \
    "$WEBHOOK_URL"
else
  echo "$MESSAGE" | logger -t shlink-ui-rails-deploy
fi
```

## 🔗 関連ドキュメント

- [CI/CDシステム](cd-system_ja.md) - 自動デプロイシステム
- [本番デプロイメント](../deployment/production_ja.md) - 手動デプロイガイド
- [設定ガイド](../configuration/settings_ja.md) - 環境設定
- [英語ドキュメント](monitoring.md) - English monitoring guide

## 📞 サポート

監視設定の問題については：
1. Webhook URLが正しく、アクセス可能であることを確認
2. 通知サービスの状態を確認（Slack、Discord）
3. 通知試行についてサーバーログをレビュー
4. curlコマンドを使用してwebhookを手動テスト
5. 既知の問題については[GitHub Issues](https://github.com/enjoydarts/shlink-ui-rails/issues)を確認

---

**ベストプラクティス**: 本番デプロイ前に監視とアラートを設定してください。通知チャンネルを定期的にテストし、重要な問題に対するエスカレーション計画を維持してください。