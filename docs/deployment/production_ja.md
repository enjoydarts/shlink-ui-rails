# 🚀 本番環境デプロイガイド

このガイドでは、Shlink-UI-Railsを本番環境にデプロイするための包括的な手順を説明します。

## 🏗️ アーキテクチャ概要

**推奨本番スタック:**
- **Webサーバー:** Caddy（HTTPS自動化、リバースプロキシ）
- **アプリケーション:** Docker化されたRailsアプリケーション
- **データベース:** 外部管理MySQL 8.4+
- **キャッシュ:** Redis（Upstash、ElastiCache、またはセルフホスト）
- **CI/CD:** GitHub Actions
- **DNS:** Cloudflare（推奨）

## 🎯 前提条件

### 必要なサービス・アカウント

| サービス | 目的 | 必要な情報 |
|---------|------|-----------|
| **クラウドプロバイダー** | サーバーホスティング | VPS/インスタンス（2+ CPU、4GB+ RAM） |
| **MySQLデータベース** | メインデータベース | 接続文字列、認証情報 |
| **Redisサービス** | キャッシュ・セッション | Redis接続URL |
| **DNSプロバイダー** | ドメイン管理 | ドメイン設定 |
| **メールサービス** | メール配信 | SMTPまたはAPI認証情報 |
| **OAuthプロバイダー** | 認証（オプション） | クライアントID、シークレット |
| **GitHub** | ソースコード・CI/CD | リポジトリ、Actions権限 |

### 必要なツール

- SSHクライアント
- Git
- DockerとDocker Compose
- テキストエディタ

## 📋 デプロイメントオプション

### オプション1: 自動セットアップ（推奨）

Docker Composeを使った高速本番デプロイメント:

#### 1.1 クローンとセットアップ
```bash
# リポジトリをクローン
git clone https://github.com/enjoydarts/shlink-ui-rails.git
cd shlink-ui-rails

# 必要なディレクトリを作成
mkdir -p logs storage tmp

# パーミッション設定（必要な場合）
sudo chown -R 1000:1000 logs storage tmp
```

#### 1.2 環境設定
`.env.production`ファイルを作成:

```bash
# アプリケーション
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
SECRET_KEY_BASE=your_very_long_secret_key_base

# データベース（外部MySQL）
DATABASE_URL=mysql2://username:password@host:3306/database_name

# Redis
REDIS_URL=redis://username:password@host:6379/0

# ドメインとURL
RAILS_FORCE_SSL=true
WEBAUTHN_RP_ID=yourdomain.com
WEBAUTHN_ORIGIN=https://yourdomain.com

# メール設定（MailerSendの例）
EMAIL_ADAPTER=mailersend
MAILERSEND_API_TOKEN=your_api_token
MAILERSEND_FROM_EMAIL=noreply@yourdomain.com

# OAuth（オプション）
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret

# セキュリティ
SECURITY_FORCE_SSL=true
SECURITY_SESSION_TIMEOUT=7200

# パフォーマンス
RAILS_MAX_THREADS=10
RAILS_MIN_THREADS=5
```

#### 1.3 アプリケーションデプロイ
```bash
# サービス開始
docker-compose -f docker-compose.prod.yml up -d

# ステータス確認
docker-compose -f docker-compose.prod.yml ps

# ログ表示
docker-compose -f docker-compose.prod.yml logs -f app
```

### オプション2: 手動サーバーセットアップ

カスタムサーバー設定の場合:

#### 2.1 サーバー準備
```bash
# システム更新
sudo apt update && sudo apt upgrade -y

# DockerとDocker Composeのインストール
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Composeインストール
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Caddyインストール（リバースプロキシ）
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install caddy
```

#### 2.2 Caddy設定
`/etc/caddy/Caddyfile`を作成:

```caddy
yourdomain.com {
    reverse_proxy localhost:3000

    # セキュリティヘッダー
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }

    # 圧縮を有効化
    encode gzip

    # ログ設定
    log {
        output file /var/log/caddy/access.log {
            roll_size 100mb
            roll_keep 5
            roll_keep_for 720h
        }
    }
}
```

#### 2.3 アプリケーションデプロイ
```bash
# アプリケーションディレクトリ作成
sudo mkdir -p /opt/shlink-ui-rails
cd /opt/shlink-ui-rails

# アプリケーションクローン
git clone https://github.com/enjoydarts/shlink-ui-rails.git .

# 環境設定
cp .env.example .env.production
# .env.productionを編集して設定

# アプリケーション開始
docker-compose -f docker-compose.prod.yml up -d

# Caddy開始
sudo systemctl enable caddy
sudo systemctl start caddy
```

## 🔧 設定詳細

### データベースセットアップ

#### 外部MySQL（推奨）
```bash
# 接続文字列の例
DATABASE_URL=mysql2://user:password@mysql-host:3306/shlink_ui_rails_production

# 管理サービス用（AWS RDS、GCP Cloud SQLなど）
DATABASE_URL=mysql2://user:password@host:3306/database?sslmode=require
```

#### スキーマ管理
```bash
# データベーススキーマ適用（デプロイ時に実行）
docker-compose exec app bundle exec ridgepole -c config/database.yml -E production --apply -f db/schemas/Schemafile
```

### Redis設定

#### 外部Redisサービス
```bash
# Upstash Redis
REDIS_URL=rediss://username:password@host:6379

# AWS ElastiCache
REDIS_URL=redis://clustercfg.cluster-name.region.cache.amazonaws.com:6379

# 認証付きセルフホストRedis
REDIS_URL=redis://username:password@host:6379/0
```

### SSL/TLS設定

#### 自動HTTPS（Caddy）
CaddyがLet's Encryptから自動的にSSL証明書を取得します。追加設定は不要です。

#### 手動SSL設定
```bash
# 必要に応じて手動で証明書をインストール
sudo mkdir -p /etc/ssl/certs/yourdomain.com
sudo cp fullchain.pem /etc/ssl/certs/yourdomain.com/
sudo cp privkey.pem /etc/ssl/certs/yourdomain.com/
```

## 🚀 CI/CDセットアップ（GitHub Actions）

### リポジトリシークレット設定

GitHubリポジトリに以下のシークレットを追加:

| シークレット名 | 値 |
|--------------|---|
| `DEPLOY_HOST` | サーバーIPアドレス |
| `DEPLOY_USER` | SSHユーザー名 |
| `DEPLOY_KEY` | SSH秘密鍵 |
| `PRODUCTION_ENV` | 完全な.env.productionの内容 |

### デプロイワークフロー

リポジトリにはGitHub Actionsワークフローが含まれており、自動デプロイを行います:

1. プルリクエスト時のテスト実行
2. `main`ブランチへのプッシュ時の本番デプロイ
3. デプロイ後のヘルスチェック
4. デプロイ失敗時の自動ロールバック

## 📊 監視・ログ管理

### ヘルスチェック
```bash
# アプリケーションヘルス
curl -f https://yourdomain.com/health || exit 1

# コンテナヘルス
docker-compose -f docker-compose.prod.yml ps

# リソース使用量
docker stats --no-stream
```

### ログ管理
```bash
# アプリケーションログ
tail -f logs/production.log

# コンテナログ
docker-compose -f docker-compose.prod.yml logs -f app

# Caddyログ
sudo tail -f /var/log/caddy/access.log
```

### ログローテーション
アプリケーションログのlogrotateを設定:

```bash
# /etc/logrotate.d/shlink-ui-railsを作成
/opt/shlink-ui-rails/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 www-data www-data
    postrotate
        docker-compose -f /opt/shlink-ui-rails/docker-compose.prod.yml restart app
    endscript
}
```

## 🆘 トラブルシューティング

### よくある問題

#### パーミッションエラー
```bash
# コンテナパーミッション修正
docker-compose exec app chown -R app:app /app/log /app/storage /app/tmp

# ホストパーミッション修正
sudo chown -R 1000:1000 logs storage tmp
```

#### データベース接続問題
```bash
# データベース接続テスト
docker-compose exec app rails runner "ActiveRecord::Base.connection.execute('SELECT 1')"

# データベース設定確認
docker-compose exec app rails runner "puts Rails.application.config.database_configuration['production']"
```

#### SSL証明書問題
```bash
# Caddy設定確認
sudo caddy validate --config /etc/caddy/Caddyfile

# Caddy再読み込み
sudo systemctl reload caddy

# 証明書ステータス確認
curl -I https://yourdomain.com
```

#### メモリ問題
```bash
# メモリ使用量確認
free -h
docker stats --no-stream

# コンテナメモリ制限最適化
# docker-compose.prod.ymlを編集してメモリ制限を追加
```

### パフォーマンス最適化

#### データベース最適化
```bash
# データベースインデックス追加（必要に応じて）
docker-compose exec app rails runner "
  ActiveRecord::Base.connection.execute('CREATE INDEX ...')
"

# データベースクエリ最適化
docker-compose exec app rails runner "
  puts ActiveRecord::Base.connection.execute('SHOW PROCESSLIST')
"
```

#### アプリケーション最適化
```bash
# アセットプリコンパイル
docker-compose exec app rails assets:precompile

# キャッシュクリア
docker-compose exec app rails cache:clear

# アプリケーション再起動
docker-compose restart app
```

## 🔧 メンテナンス

### 定期メンテナンス作業

#### 日次
```bash
# アプリケーションヘルス確認
curl -f https://yourdomain.com/health

# ディスク容量監視
df -h

# コンテナステータス確認
docker-compose ps
```

#### 週次
```bash
# システムパッケージ更新
sudo apt update && sudo apt upgrade -y

# Dockerイメージクリーンアップ
docker system prune -f

# データベースバックアップ
# （データベースサービスの自動バックアップを設定）
```

#### 月次
```bash
# アプリケーション更新
git pull origin main
docker-compose build --no-cache
docker-compose up -d

# エラーログレビュー
grep -i error logs/production.log

# セキュリティ更新
sudo apt update && sudo apt upgrade -y
```

## 🔗 追加リソース

- [設定ガイド](../configuration/settings_ja.md) - 詳細な設定オプション
- [運用ガイド](../operations/cd-system_ja.md) - CI/CDと監視
- [開発環境セットアップ](../setup/development_ja.md) - 開発環境
- [英語ドキュメント](production.md) - English deployment guide

## 🆘 サポート

デプロイメントの問題については:
1. 上記の[トラブルシューティング](#トラブルシューティング)セクションを確認
2. [GitHub Issues](https://github.com/enjoydarts/shlink-ui-rails/issues)をレビュー
3. アプリケーションログとサーバーログを確認
4. すべての環境変数が正しく設定されていることを確認

---

**セキュリティ注意**: 本番環境では必ずHTTPSを使用し、依存関係を最新に保ち、サーバーとデータベース設定でセキュリティベストプラクティスに従ってください。