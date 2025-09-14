# Shlink-UI-Rails 本番デプロイ手順書（日本語版）

## 概要

この手順書では、Shlink-UI-Rails アプリケーションをOCI（Oracle Cloud Infrastructure）のAmpere A1インスタンスに本番デプロイする詳細な手順を説明します。

**構成概要:**
- **Webサーバー:** Caddy（HTTPS自動化、リバースプロキシ）
- **アプリケーション:** Docker化されたRailsアプリ
- **データベース:** 外部マネージドMySQL
- **キャッシュ:** Upstash Redis
- **CI/CD:** GitHub Actions
- **ドメイン:** app.kety.at（Cloudflare DNS）

---

## 前提条件

### 必要なサービス・アカウント

| サービス | 用途 | 必要な情報 |
|----------|------|------------|
| **OCI（Oracle Cloud Infrastructure）** | サーバーホスティング | Ampere A1 インスタンス |
| **外部マネージドMySQL** | データベース | 接続文字列、認証情報 |
| **Upstash** | Redis キャッシュ | Redis接続URL |
| **Cloudflare** | DNS管理 | ドメイン: app.kety.at |
| **MailerSend** | メール送信 | APIトークン |
| **Google Cloud Console** | OAuth2認証 | クライアントID、シークレット |
| **GitHub** | ソースコード・CI/CD | リポジトリ、Actions権限 |

### 必要なツール

- SSH クライアント
- Git
- テキストエディタ

---

## Step 1: OCI インスタンス設定

### 1.1 インスタンス作成

**推奨スペック:**
- **Shape:** VM.Standard.A1.Flex
- **OCPU:** 4 コア
- **Memory:** 24GB RAM
- **OS:** Ubuntu 22.04 LTS（ARM64）
- **ストレージ:** 100GB以上

**セキュリティグループ設定:**
- SSH（ポート22）: 管理元IPからのみ許可
- HTTP（ポート80）: 全て許可
- HTTPS（ポート443）: 全て許可

### 1.2 初期設定とセキュリティ強化

インスタンスにSSH接続して以下を実行：

```bash
# システムアップデート
sudo apt update && sudo apt upgrade -y

# 基本パッケージインストール
sudo apt install -y curl wget git unzip fail2ban ufw htop

# ファイアウォール設定（重要: SSH接続が切れないよう注意）
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
# ファイアウォールを有効化（SSH接続を確認してから実行）
sudo ufw --force enable

# SSH攻撃対策（fail2ban）
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# fail2banの状態確認
sudo fail2ban-client status
```

### 1.3 専用ユーザー作成とディレクトリ設定

```bash
# アプリケーション専用ユーザー作成
# --system: システムユーザーとして作成
# --group: 同名のグループも作成
# --home: ホームディレクトリを /opt/shlink-ui-rails に設定
# --shell: ログインシェルを設定
sudo adduser --system --group --home /opt/shlink-ui-rails --shell /bin/bash shlink

# 必要なディレクトリ構造を作成
sudo mkdir -p /opt/shlink-ui-rails/{app,config,logs,backups,scripts,tmp,storage}
sudo chown -R shlink:shlink /opt/shlink-ui-rails

# ログディレクトリ作成（システム全体のログ用）
sudo mkdir -p /var/log/shlink-ui-rails
sudo chown shlink:shlink /var/log/shlink-ui-rails

# ディレクトリ構造確認
ls -la /opt/shlink-ui-rails/
```

### 1.4 Docker インストール

```bash
# Docker公式インストールスクリプト使用
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Docker Compose インストール（最新版を確認して URL を更新してください）
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 専用ユーザーをdockerグループに追加
sudo usermod -aG docker shlink

# Docker サービス自動起動設定
sudo systemctl enable docker
sudo systemctl start docker

# インストール確認
docker --version
docker-compose --version
```

### 1.5 Caddy Webサーバーインストール

```bash
# Caddy公式リポジトリ追加
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list

# Caddy インストール
sudo apt update
sudo apt install caddy

# Caddy サービス確認
sudo systemctl status caddy
```

---

## Step 2: 環境変数とアプリケーション設定

### 2.1 環境変数ファイル作成

専用ユーザーで環境変数ファイルを作成：

```bash
# 専用ユーザーに切り替え
sudo su - shlink

# アプリケーションディレクトリに移動
cd /opt/shlink-ui-rails

# 環境変数ファイルを作成（セキュア権限で）
cat > .env.production << 'EOF'
# Rails基本設定
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
LOG_LEVEL=info

# セキュリティ設定（必ず変更してください）
SECRET_KEY_BASE=your-very-long-secret-key-here-change-this
DEVISE_SECRET_KEY=your-devise-secret-key-here-change-this
SECURITY_FORCE_SSL=true
SECURITY_HEADERS_ENABLED=true

# データベース設定（マネージドMySQLの情報に変更）
DATABASE_URL=mysql2://username:password@mysql-host:3306/shlink_ui_rails_production

# Redis設定（Upstashの情報に変更）
REDIS_URL=rediss://default:password@redis-host:6380

# Google OAuth2設定（Google Cloud Consoleから取得）
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret

# メール送信設定（MailerSendから取得）
MAILERSEND_API_TOKEN=your-mailersend-api-token
MAIL_FROM=noreply@app.kety.at

# Shlink API設定（あなたのShlinkサーバー情報に変更）
SHLINK_BASE_URL=https://your-shlink-server.com
SHLINK_API_KEY=your-shlink-api-key

# WebAuthn設定
WEBAUTHN_RP_NAME=Shlink-UI-Rails
WEBAUTHN_RP_ID=app.kety.at
WEBAUTHN_ORIGIN=https://app.kety.at

# アプリケーション設定
APP_HOST=app.kety.at
APP_PROTOCOL=https
APP_TIMEZONE=Tokyo
EOF

# ファイル権限を制限（重要: セキュリティ対策）
chmod 600 .env.production

# 元のユーザーに戻る
exit
```

### 2.2 秘密キー生成

```bash
# 一時的にRails環境を作ってキーを生成
# 本格運用前に以下のコマンドで強力な秘密キーを生成してください

# SECRET_KEY_BASE用
openssl rand -hex 64

# DEVISE_SECRET_KEY用
openssl rand -hex 64

# 生成された文字列を .env.production ファイルの該当箇所に設定してください
```

---

## Step 3: Caddy設定

### 3.1 Caddyfile設定

```bash
# Caddyfileを設定
sudo tee /etc/caddy/Caddyfile << 'EOF'
# app.kety.at の設定
app.kety.at {
	# Railsアプリケーションへのリバースプロキシ
	reverse_proxy localhost:3000 {
		# ヘルスチェック設定
		health_uri /health
		health_interval 10s
		health_timeout 5s
	}

	# セキュリティヘッダー
	header {
		# HTTPS強制
		Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
		# XSS対策
		X-Content-Type-Options "nosniff"
		X-Frame-Options "SAMEORIGIN"
		X-XSS-Protection "1; mode=block"
		# その他
		Referrer-Policy "strict-origin-when-cross-origin"
		# サーバー情報隠蔽
		-Server
		-X-Powered-By
	}

	# レート制限（DDoS対策）
	rate_limit {
		zone general {
			key {remote_host}
			events 100
			window 1m
		}
	}

	# ログ設定
	log {
		output file /var/log/caddy/app.kety.at.log {
			roll_size 100MB
			roll_keep 10
		}
		format json
	}

	# エラーページ
	handle_errors {
		@404 expression {http.error.status_code} == 404
		@5xx expression {http.error.status_code} >= 500 && {http.error.status_code} < 600

		handle @404 {
			respond "Not Found" 404
		}
		handle @5xx {
			respond "Server Error" 500
		}
	}
}

# HTTP→HTTPSリダイレクト
http://app.kety.at {
	redir https://app.kety.at{uri} permanent
}
EOF

# Caddyログディレクトリ作成
sudo mkdir -p /var/log/caddy
sudo chown caddy:caddy /var/log/caddy

# Caddy設定をテスト
sudo caddy validate --config /etc/caddy/Caddyfile

# Caddy サービス有効化・開始
sudo systemctl enable caddy
sudo systemctl restart caddy

# 状態確認
sudo systemctl status caddy
```

---

## Step 4: systemdサービス設定

### 4.1 アプリケーション自動起動設定

```bash
# systemdサービスファイル作成
sudo tee /etc/systemd/system/shlink-ui-rails.service << 'EOF'
[Unit]
Description=Shlink UI Rails Application
After=docker.service network-online.target
Wants=network-online.target
Requires=docker.service

[Service]
Type=forking
User=shlink
Group=shlink
WorkingDirectory=/opt/shlink-ui-rails

# 環境変数ファイル読み込み
EnvironmentFile=/opt/shlink-ui-rails/.env.production

# サービス実行コマンド
ExecStartPre=/usr/local/bin/docker-compose -f docker-compose.prod.yml pull --quiet
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
ExecReload=/usr/local/bin/docker-compose -f docker-compose.prod.yml restart

# 再起動設定
Restart=always
RestartSec=10

# セキュリティ設定
NoNewPrivileges=true
PrivateTmp=true

# タイムアウト設定
TimeoutStartSec=300
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

# systemd設定リロード
sudo systemctl daemon-reload

# サービス有効化（自動起動設定）
sudo systemctl enable shlink-ui-rails
```

---

## Step 5: GitHub Actions設定

### 5.1 GitHub Secrets設定

GitHubリポジトリの **Settings** → **Secrets and variables** → **Actions** で以下のシークレットを追加：

| シークレット名 | 値 | 説明 |
|----------------|------|------|
| `OCI_HOST` | `your-instance-ip` | OCIインスタンスのパブリックIP |
| `OCI_USERNAME` | `shlink` | 専用ユーザー名 |
| `OCI_SSH_PRIVATE_KEY` | `-----BEGIN OPENSSH PRIVATE KEY-----...` | SSH秘密鍵（後述の手順で作成） |
| `GITHUB_TOKEN` | 自動生成 | Docker registry用（通常は自動設定） |

### 5.2 SSH キー設定

```bash
# 専用ユーザーでSSHキー生成
sudo -u shlink ssh-keygen -t ed25519 -f /opt/shlink-ui-rails/.ssh/id_ed25519 -N ""

# SSH設定ディレクトリと権限設定
sudo -u shlink mkdir -p /opt/shlink-ui-rails/.ssh
sudo -u shlink chmod 700 /opt/shlink-ui-rails/.ssh
sudo -u shlink chmod 600 /opt/shlink-ui-rails/.ssh/id_ed25519
sudo -u shlink chmod 644 /opt/shlink-ui-rails/.ssh/id_ed25519.pub

# 公開鍵をauthorized_keysに追加
sudo -u shlink cp /opt/shlink-ui-rails/.ssh/id_ed25519.pub /opt/shlink-ui-rails/.ssh/authorized_keys
sudo -u shlink chmod 600 /opt/shlink-ui-rails/.ssh/authorized_keys

# 秘密鍵をGitHub Secretsに設定するために表示
sudo cat /opt/shlink-ui-rails/.ssh/id_ed25519
```

**重要:** 表示された秘密鍵をGitHubの `OCI_SSH_PRIVATE_KEY` シークレットに設定してください。

---

## Step 6: 初回デプロイ

### 6.1 アプリケーションコードの配置

```bash
# 専用ユーザーでGitリポジトリクローン
sudo -u shlink git clone https://github.com/your-username/shlink-ui-rails.git /opt/shlink-ui-rails/app

# 必要なファイルをシンボリックリンク
sudo -u shlink ln -sf /opt/shlink-ui-rails/app/docker-compose.prod.yml /opt/shlink-ui-rails/docker-compose.prod.yml
sudo -u shlink ln -sf /opt/shlink-ui-rails/app/Dockerfile.production /opt/shlink-ui-rails/Dockerfile.production

# ディレクトリ構造確認
sudo -u shlink ls -la /opt/shlink-ui-rails/
```

### 6.2 Dockerイメージビルドと初回起動

```bash
# 専用ユーザーに切り替え
sudo su - shlink
cd /opt/shlink-ui-rails

# 環境変数ファイルの存在確認
ls -la .env.production

# Dockerイメージのビルド（初回のみ）
docker-compose -f docker-compose.prod.yml build

# データベース初期化（重要: 必ず最初に実行）
docker-compose -f docker-compose.prod.yml run --rm app rails db:create
docker-compose -f docker-compose.prod.yml run --rm app rails db:migrate
docker-compose -f docker-compose.prod.yml run --rm app rails db:seed

# アプリケーション起動
docker-compose -f docker-compose.prod.yml up -d

# 起動状況確認
docker-compose -f docker-compose.prod.yml ps

# ログ確認
docker-compose -f docker-compose.prod.yml logs app

# 元のユーザーに戻る
exit
```

### 6.3 systemdサービス開始

```bash
# systemdサービス開始
sudo systemctl start shlink-ui-rails

# 状態確認
sudo systemctl status shlink-ui-rails

# ログ確認
sudo journalctl -u shlink-ui-rails -f
```

---

## Step 7: DNS設定（Cloudflare）

### 7.1 DNSレコード設定

Cloudflareダッシュボードで以下の設定を行います：

**Aレコード設定:**
- **Type:** A
- **Name:** app
- **IPv4 address:** [OCIインスタンスのパブリックIP]
- **TTL:** Auto
- **Proxy status:** 🟠 Proxied（オレンジクラウド）

### 7.2 SSL/TLS設定

Cloudflareで以下を設定：
- **SSL/TLS設定:** Full (strict)
- **Always Use HTTPS:** 有効化
- **HTTP Strict Transport Security (HSTS):** 有効化

---

## Step 8: バックアップ・監視設定

### 8.1 バックアップスクリプト設定

```bash
# バックアップスクリプト作成
sudo -u shlink tee /opt/shlink-ui-rails/scripts/backup.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# 設定
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/shlink-ui-rails/backups"
RETENTION_DAYS=30
LOG_FILE="/var/log/shlink-ui-rails/backup.log"

# ログ関数
log() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

# バックアップ開始
log "Starting backup process"

# バックアップディレクトリ作成
mkdir -p "$BACKUP_DIR"

# 環境変数読み込み
source /opt/shlink-ui-rails/.env.production

# データベースバックアップ
log "Creating database backup"
# DATABASE_URLから情報を抽出
DB_HOST=$(echo $DATABASE_URL | sed 's/.*@\([^:]*\):.*/\1/')
DB_PORT=$(echo $DATABASE_URL | sed 's/.*:\([0-9]*\)\/.*/\1/')
DB_NAME=$(echo $DATABASE_URL | sed 's/.*\/\([^?]*\).*/\1/')
DB_USER=$(echo $DATABASE_URL | sed 's/.*:\/\/\([^:]*\):.*/\1/')
DB_PASS=$(echo $DATABASE_URL | sed 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/')

# データベースダンプ
mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$BACKUP_DIR/db_backup_$DATE.sql.gz"

# アプリケーションファイルバックアップ
log "Creating application backup"
tar -czf "$BACKUP_DIR/app_backup_$DATE.tar.gz" -C /opt/shlink-ui-rails \
    --exclude=backups \
    --exclude=logs \
    --exclude=tmp \
    .

# 古いバックアップ削除
log "Cleaning old backups"
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

log "Backup process completed successfully"
EOF

# スクリプト実行権限付与
sudo chown shlink:shlink /opt/shlink-ui-rails/scripts/backup.sh
sudo chmod 750 /opt/shlink-ui-rails/scripts/backup.sh

# crontab設定（毎日午前2時にバックアップ実行）
sudo -u shlink crontab << 'EOF'
# 毎日午前2時にバックアップ実行
0 2 * * * /opt/shlink-ui-rails/scripts/backup.sh
EOF

# crontab確認
sudo -u shlink crontab -l
```

### 8.2 ログローテーション設定

```bash
# logrotate設定
sudo tee /etc/logrotate.d/shlink-ui-rails << 'EOF'
/var/log/caddy/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 caddy caddy
    postrotate
        systemctl reload caddy
    endscript
}

/var/log/shlink-ui-rails/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 shlink shlink
}
EOF
```

---

## Step 9: 動作確認とテスト

### 9.1 基本動作確認

```bash
# サービス状態確認
sudo systemctl status caddy
sudo systemctl status shlink-ui-rails

# ポート確認
sudo netstat -tlnp | grep -E ':(80|443|3000)'

# Docker コンテナ状態確認
sudo -u shlink docker-compose -f /opt/shlink-ui-rails/docker-compose.prod.yml ps

# ヘルスチェック確認
curl -f http://localhost:3000/health
curl -f https://app.kety.at/health
```

### 9.2 ログ確認

```bash
# アプリケーションログ
sudo -u shlink docker-compose -f /opt/shlink-ui-rails/docker-compose.prod.yml logs app

# Caddyログ
sudo tail -f /var/log/caddy/app.kety.at.log

# systemdログ
sudo journalctl -u shlink-ui-rails -f
sudo journalctl -u caddy -f
```

### 9.3 セキュリティ確認

```bash
# ファイアウォール状態確認
sudo ufw status verbose

# fail2ban状態確認
sudo fail2ban-client status sshd

# SSL証明書確認
echo | openssl s_client -connect app.kety.at:443 -servername app.kety.at 2>/dev/null | openssl x509 -noout -text

# セキュリティヘッダー確認
curl -I https://app.kety.at/
```

---

## トラブルシューティング

### よくある問題と対処法

#### 1. Docker コンテナが起動しない

```bash
# ログを確認
sudo -u shlink docker-compose -f /opt/shlink-ui-rails/docker-compose.prod.yml logs app

# リソース使用状況確認
sudo -u shlink docker stats
free -h
df -h

# 環境変数確認
sudo -u shlink cat /opt/shlink-ui-rails/.env.production
```

#### 2. データベース接続エラー

```bash
# 接続テスト
sudo -u shlink docker-compose -f /opt/shlink-ui-rails/docker-compose.prod.yml run --rm app rails runner "ActiveRecord::Base.connection.execute('SELECT 1')"

# ネットワーク確認
ping mysql-host-name
telnet mysql-host-name 3306
```

#### 3. SSL証明書の問題

```bash
# Caddyログ確認
sudo journalctl -u caddy -f

# 証明書再取得
sudo systemctl restart caddy

# DNS設定確認
nslookup app.kety.at
```

#### 4. GitHub Actions デプロイエラー

```bash
# SSH接続確認
ssh -o StrictHostKeyChecking=no shlink@your-instance-ip

# GitHub Secrets確認
# リポジトリのSettings → Secrets and variables → Actionsで設定を確認

# デプロイログ確認
sudo cat /opt/shlink-ui-rails/logs/deploy.log
```

#### 5. パフォーマンス問題

```bash
# システムリソース確認
top
htop
iostat
vmstat 1

# アプリケーションのメトリクス確認
sudo -u shlink docker-compose -f /opt/shlink-ui-rails/docker-compose.prod.yml exec app rails runner "puts Rails.cache.stats"

# Caddyのアクセスログ分析
sudo tail -f /var/log/caddy/app.kety.at.log | jq .
```

---

## 定期メンテナンス

### 週次作業

```bash
# システム更新
sudo apt update && sudo apt upgrade -y

# Docker cleanup
sudo -u shlink docker system prune -f

# ログサイズ確認
du -sh /var/log/caddy/
du -sh /var/log/shlink-ui-rails/
du -sh /opt/shlink-ui-rails/logs/
```

### 月次作業

```bash
# バックアップ状況確認
ls -la /opt/shlink-ui-rails/backups/

# セキュリティ更新確認
sudo fail2ban-client status
sudo ufw status

# パフォーマンス分析
# アクセスログの分析、リソース使用状況の確認等
```

---

## セキュリティベストプラクティス

### 重要な設定確認

1. **環境変数ファイル権限:** `chmod 600 .env.production`
2. **SSH設定:** パスワード認証無効化、鍵認証のみ
3. **ファイアウォール:** 必要最小限のポートのみ開放
4. **SSL/TLS:** 強固な暗号化設定
5. **レート制限:** DDoS攻撃対策
6. **ログ監視:** 異常なアクセスパターンの検出

### 定期的なセキュリティ監査

- システム更新の適用
- SSL証明書の有効期限確認
- ログの異常検知
- バックアップの整合性確認
- アクセス権限の見直し

---

## サポート・問い合わせ

問題が発生した場合は、以下の情報を整理してからサポートに連絡してください：

1. **エラーメッセージ**（完全なスタックトレース）
2. **ログファイル**（関連する部分）
3. **実行した操作**（再現手順）
4. **環境情報**（OS、Docker、サービスのバージョン）

**ログファイルの場所:**
- アプリケーション: `docker-compose logs`
- Caddy: `/var/log/caddy/app.kety.at.log`
- システム: `/var/log/syslog`
- デプロイ: `/opt/shlink-ui-rails/logs/deploy.log`

---

**📝 注意:** この手順書は定期的に更新されます。最新版を確認してから作業を行ってください。