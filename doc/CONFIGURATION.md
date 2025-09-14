# Shlink-UI-Rails 設定ガイド

## 統一設定システム概要

Shlink-UI-Railsは統一設定システム（ApplicationConfig）を使用しており、以下の優先順位で設定値を管理しています：

```
1. SystemSetting (データベース) - 管理画面から変更可能
2. 環境変数 (ENV)             - デプロイメント時に指定
3. config gem (Settings)      - アプリケーション設定ファイル
4. デフォルト値                - コード内で定義
```

## 設定方法

### 1. 必須設定（環境変数で設定）

これらの設定は必ず環境変数で指定する必要があります：

```bash
# Rails基本設定
RAILS_ENV=production
SECRET_KEY_BASE=your-secret-key-base

# データベース設定
DATABASE_HOST=your-database-host
DATABASE_NAME=shlink_ui_rails_production
DATABASE_USER=your-database-user
DATABASE_PASSWORD=your-database-password

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
```

#### メール設定
```bash
EMAIL_ADAPTER=smtp
EMAIL_FROM_ADDRESS=noreply@your-domain.com
EMAIL_SMTP_ADDRESS=smtp.gmail.com
EMAIL_SMTP_PORT=587
EMAIL_SMTP_USER_NAME=your-email@gmail.com
EMAIL_SMTP_PASSWORD=your-app-password
```

## 設定の使用方法

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

## 環境変数の命名規則

環境変数名は設定キーを大文字に変換し、ドット（.）をアンダースコア（_）に置換します：

| 設定キー | 環境変数名 |
|----------|------------|
| `captcha.enabled` | `CAPTCHA_ENABLED` |
| `email.smtp.address` | `EMAIL_SMTP_ADDRESS` |
| `rate_limit.login.requests_per_hour` | `RATE_LIMIT_LOGIN_REQUESTS_PER_HOUR` |

## デバッグ方法

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

## 管理画面での設定

1. 管理ダッシュボードにアクセス
2. 「システム設定」をクリック
3. 各カテゴリの設定を変更
4. 「保存」をクリックして設定を適用

変更された設定は即座にアプリケーション全体に反映されます。

## トラブルシューティング

### 設定が反映されない場合

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