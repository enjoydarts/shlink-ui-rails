# 🔧 設定ガイド

このガイドでは、Shlink-UI-Railsで使用される統一設定システムと、アプリケーション設定の管理方法について説明します。

## 🏗️ 設定システム概要

Shlink-UI-Railsは統一設定システム（ApplicationConfig）を使用しており、以下の優先順位で設定値を管理しています：

```
1. SystemSetting (データベース) - 管理画面から変更可能
2. 環境変数 (ENV)             - デプロイメント時に指定
3. config gem (Settings)      - アプリケーション設定ファイル
4. デフォルト値                - コード内で定義
```

## ⚙️ 設定方法

### 1. 必須設定（環境変数で設定）

これらの設定は必ず環境変数で指定する必要があります：

```bash
# Rails基本設定
RAILS_ENV=production
SECRET_KEY_BASE=your-very-long-secret-key-base

# データベース設定
DATABASE_URL=mysql2://user:password@host:3306/database_name

# Shlink API設定
SHLINK_BASE_URL=https://your-shlink-server.com
SHLINK_API_KEY=your-shlink-api-key

# Redis設定
REDIS_URL=redis://your-redis-host:6379/0
```

### 2. オプション設定（管理画面または環境変数）

これらの設定は管理画面から動的に変更でき、環境変数でデフォルト値を上書きできます：

#### CAPTCHA設定
```bash
CAPTCHA_ENABLED=false
CAPTCHA_SITE_KEY=your-turnstile-site-key
CAPTCHA_SECRET_KEY=your-turnstile-secret-key
```

#### レート制限設定
```bash
RATE_LIMIT_ENABLED=true
RATE_LIMIT_LOGIN_REQUESTS_PER_HOUR=10
RATE_LIMIT_REGISTRATION_REQUESTS_PER_HOUR=5
RATE_LIMIT_API_REQUESTS_PER_MINUTE=60
```

#### メール設定
```bash
# SMTP設定
EMAIL_ADAPTER=smtp
EMAIL_FROM_ADDRESS=noreply@your-domain.com
EMAIL_SMTP_ADDRESS=smtp.gmail.com
EMAIL_SMTP_PORT=587
EMAIL_SMTP_USER_NAME=your-email@gmail.com
EMAIL_SMTP_PASSWORD=your-app-password
EMAIL_SMTP_AUTHENTICATION=plain
EMAIL_SMTP_ENABLE_STARTTLS_AUTO=true

# MailerSend設定
EMAIL_ADAPTER=mailersend
MAILERSEND_API_TOKEN=your-api-token
MAILERSEND_FROM_EMAIL=noreply@your-domain.com
```

#### OAuth設定
```bash
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

#### WebAuthn設定（セキュリティキー）
```bash
WEBAUTHN_RP_NAME=Your-App-Name
WEBAUTHN_RP_ID=your-domain.com
WEBAUTHN_ORIGIN=https://your-domain.com
WEBAUTHN_TIMEOUT=60000
```

#### セキュリティ設定
```bash
SECURITY_REQUIRE_STRONG_PASSWORD=true
SECURITY_MAX_LOGIN_ATTEMPTS=5
SECURITY_SESSION_TIMEOUT=7200
SECURITY_FORCE_SSL=true
```

#### パフォーマンス設定
```bash
PERFORMANCE_CACHE_TTL=3600
PERFORMANCE_DATABASE_POOL_SIZE=10
PERFORMANCE_BACKGROUND_JOB_THREADS=5
```

## 🛠️ 設定の使用方法

### コード内での設定取得

#### 1. ApplicationConfig（直接アクセス）
```ruby
# 基本的な設定取得
ApplicationConfig.get('captcha.enabled', false)

# 型別専用メソッド
ApplicationConfig.enabled?('captcha.enabled')       # boolean
ApplicationConfig.number('captcha.timeout', 10)     # integer
ApplicationConfig.string('email.adapter', 'smtp')   # string
ApplicationConfig.array('allowed.domains', [])      # array

# カテゴリ一括取得
ApplicationConfig.category('captcha')
```

#### 2. ConfigShortcuts（便利メソッド）
```ruby
# コントローラー、モデル、ジョブ、メーラーで利用可能
captcha_enabled?           # CAPTCHA有効/無効
shlink_base_url           # Shlink API URL
email_adapter             # メールアダプター
smtp_settings             # SMTP設定一式
redis_url                 # Redis接続URL
```

### 設定の動的変更

```ruby
# 設定値の更新（管理画面から実行される）
ApplicationConfig.set('captcha.enabled', true, type: 'boolean', category: 'captcha')

# 設定のリセット（デフォルト値に戻す）
ApplicationConfig.reset('captcha.enabled')

# システム設定の再読み込み（設定変更後）
ApplicationConfig.reload!
```

## 📝 環境変数の命名規則

環境変数名は設定キーを大文字に変換し、ドット（.）をアンダースコア（_）に置換します：

| 設定キー | 環境変数名 |
|----------|------------|
| `captcha.enabled` | `CAPTCHA_ENABLED` |
| `email.smtp.address` | `EMAIL_SMTP_ADDRESS` |
| `rate_limit.login.requests_per_hour` | `RATE_LIMIT_LOGIN_REQUESTS_PER_HOUR` |

## 🖥️ 管理画面での設定

### システム設定へのアクセス

1. 管理ダッシュボードにアクセス
2. 「システム設定」をクリック
3. 各カテゴリの設定を変更
4. 「保存」をクリックして設定を適用

変更された設定は即座にアプリケーション全体に反映されます。

### 利用可能な設定カテゴリ

#### 基本システム
- サイト名と説明
- デフォルトタイムゾーン
- ページネーション設定

#### セキュリティ
- パスワード要件
- セッション設定
- SSL強制

#### CAPTCHA
- CAPTCHA有効/無効
- Turnstile設定
- CAPTCHAタイムアウト設定

#### レート制限
- ログイン試行制限
- 登録制限
- API レート制限

#### メール
- メールアダプター選択
- SMTP設定
- MailerSend設定

#### パフォーマンス
- キャッシュ設定
- データベースプール設定
- バックグラウンドジョブ設定

## 🔍 デバッグとトラブルシューティング

### 設定値の確認
```ruby
# Railsコンソールで設定値を確認
ApplicationConfig.get('captcha.enabled')

# 設定の優先順位を確認
puts "SystemSetting: #{SystemSetting.get('captcha.enabled')}"
puts "環境変数: #{ENV['CAPTCHA_ENABLED']}"
puts "config gem: #{Settings.captcha.enabled}"
puts "統一システム: #{ApplicationConfig.get('captcha.enabled')}"
```

### 設定キャッシュのクリア
```ruby
# 本番環境でキャッシュをクリア
Rails.cache.delete_matched("app_config:*")
```

### 設定が反映されない場合

設定が有効にならない場合は：

1. 設定の優先順位を確認
2. SystemSettingテーブルに値が保存されているか確認
3. アプリケーションの再起動
4. キャッシュのクリア（本番環境）

### 設定のリセット

```bash
# 全設定をデフォルトに戻す
docker compose exec web rails runner "SystemSetting.destroy_all; SystemSetting.initialize_defaults!"

# 特定カテゴリをリセット
docker compose exec web rails runner "SystemSetting.by_category('captcha').destroy_all; SystemSetting.initialize_defaults!"
```

## 🧪 設定のテスト

### 環境変数のテスト
```bash
# SMTP設定のテスト
docker compose exec web rails runner "
  begin
    ActionMailer::Base.mail(
      from: ENV['EMAIL_FROM_ADDRESS'],
      to: 'test@example.com',
      subject: 'Test Email',
      body: 'Configuration test'
    ).deliver_now
    puts 'メール設定が動作しています！'
  rescue => e
    puts \"メールエラー: \#{e.message}\"
  end
"

# データベース接続のテスト
docker compose exec web rails runner "
  begin
    ActiveRecord::Base.connection.execute('SELECT 1')
    puts 'データベース接続が動作しています！'
  rescue => e
    puts \"データベースエラー: \#{e.message}\"
  end
"

# Redis接続のテスト
docker compose exec web rails runner "
  begin
    Redis.new(url: ENV['REDIS_URL']).ping
    puts 'Redis接続が動作しています！'
  rescue => e
    puts \"Redisエラー: \#{e.message}\"
  end
"
```

## 📊 設定例

### 開発環境
```bash
# .env.development
RAILS_ENV=development
DATABASE_URL=mysql2://root@db:3306/shlink_ui_rails_development
REDIS_URL=redis://redis:6379/0
SHLINK_BASE_URL=http://localhost:8080
SHLINK_API_KEY=your-dev-api-key
EMAIL_ADAPTER=letter_opener
CAPTCHA_ENABLED=false
```

### 本番環境
```bash
# .env.production
RAILS_ENV=production
SECRET_KEY_BASE=your-very-long-secret-key-base
DATABASE_URL=mysql2://user:password@mysql-host:3306/shlink_ui_rails_production
REDIS_URL=rediss://user:password@redis-host:6379
SHLINK_BASE_URL=https://shlink.yourdomain.com
SHLINK_API_KEY=your-production-api-key
EMAIL_ADAPTER=mailersend
MAILERSEND_API_TOKEN=your-mailersend-token
MAILERSEND_FROM_EMAIL=noreply@yourdomain.com
CAPTCHA_ENABLED=true
CAPTCHA_SITE_KEY=your-turnstile-site-key
CAPTCHA_SECRET_KEY=your-turnstile-secret-key
WEBAUTHN_RP_ID=yourdomain.com
WEBAUTHN_ORIGIN=https://yourdomain.com
SECURITY_FORCE_SSL=true
SECURITY_REQUIRE_STRONG_PASSWORD=true
```

## 🔗 関連ドキュメント

- [開発環境セットアップ](../setup/development_ja.md) - 開発環境の設定
- [本番デプロイメント](../deployment/production_ja.md) - 本番環境のセットアップ
- [英語ドキュメント](settings.md) - English configuration guide

## 🆘 サポート

設定の問題については：
1. 上記のトラブルシューティングセクションを確認
2. 環境変数が正しく設定されていることを確認
3. [GitHub Issues](https://github.com/enjoydarts/shlink-ui-rails/issues)をレビュー
4. 個別コンポーネント（データベース、Redis、メール）を個別にテスト

---

**セキュリティ注意**: 機密設定値（APIキー、パスワード、シークレット）をバージョン管理にコミットしないでください。必ず環境変数または安全なシークレット管理システムを使用してください。