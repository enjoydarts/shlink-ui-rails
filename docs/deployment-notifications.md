# デプロイ通知設定

デプロイスクリプトでは成功・失敗時に自動通知を送信できます。

## 対応している通知手段

### 1. Slack通知
Slack Webhook URLを使用してチャンネルに通知を送信

```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
```

### 2. Discord通知
Discord Webhook URLを使用してチャンネルに通知を送信

```bash
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK"
```

### 3. メール通知
sendmailを使用してメール通知を送信

```bash
export NOTIFICATION_EMAIL="admin@example.com"
```

## 通知内容

### 成功時
```
🚀 **デプロイ完了**
**プロジェクト:** Shlink-UI-Rails
**環境:** Production (app.kty.at)
**コミット:** `abc1234`
**イメージ:** `ghcr.io/enjoydarts/shlink-ui-rails:latest`
**時刻:** 2025-09-16 14:30:00 JST
```

### 失敗時
```
🚨 **デプロイ失敗**
**プロジェクト:** Shlink-UI-Rails
**環境:** Production (app.kty.at)
**コミット:** `abc1234`
**イメージ:** `ghcr.io/enjoydarts/shlink-ui-rails:latest`
**時刻:** 2025-09-16 14:30:00 JST

**エラー:** Deployment failed at line 123 (exit code: 1)
```

## サーバー上での設定

### .env.production に追加
```bash
# デプロイ通知設定
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK
NOTIFICATION_EMAIL=admin@example.com
```

### GitHub Secretsに追加（CI/CD用）
1. GitHub リポジトリ → Settings → Secrets and variables → Actions
2. 以下のシークレットを追加:
   - `SLACK_WEBHOOK_URL`
   - `DISCORD_WEBHOOK_URL`
   - `NOTIFICATION_EMAIL`

## Webhook URL の取得方法

### Slack
1. Slack App 設定 → Incoming Webhooks
2. チャンネルを選択してWebhook URLを生成

### Discord
1. Discord チャンネル設定 → 連携サービス → ウェブフック
2. 新しいWebhookを作成してURLをコピー

## システムログ
環境変数を設定していない場合も、システムログ（journalctl）に通知内容が記録されます：

```bash
journalctl -t shlink-ui-rails-deploy
```