# 🚀 開発環境セットアップガイド

このガイドでは、Shlink-UI-Railsの開発環境をセットアップする手順を説明します。

## 🎯 前提条件

- Docker and Docker Compose
- Git
- Ruby 3.4.5（Dockerを使わないローカル開発の場合）
- MySQL 8.4+（Dockerを使わないローカル開発の場合）

## 📋 Dockerを使ったクイックスタート（推奨）

### 1. リポジトリのクローン
```bash
git clone https://github.com/enjoydarts/shlink-ui-rails.git
cd shlink-ui-rails
```

### 2. 初回セットアップ
```bash
# サービスを開始してデータベースをセットアップ
make setup

# または手動で：
# docker compose up -d
# docker compose exec web bundle exec ridgepole -c config/database.yml -E development --apply -f db/schemas/Schemafile
# docker compose exec web rails db:seed
```

### 3. アプリケーションへのアクセス
- **Webアプリケーション**: http://localhost:3000
- **管理者アカウント**:
  - メールアドレス: `admin@example.com`
  - パスワード: `password`

⚠️ **セキュリティ注意**: 開発環境でも初回ログイン後に管理者パスワードを変更してください

## 🔧 開発コマンド

### 基本コマンド
```bash
# サービス起動
make up

# サービス停止
make down

# テスト実行
make test

# リンター実行
make lint

# リンターの自動修正
make lint-fix

# ログ表示
make logs

# Railsコンソール起動
make console

# マイグレーション実行（Ridgepole使用）
make db-migrate
```

### 手動Dockerコマンド
```bash
# サービスのビルドと起動
docker compose up -d

# アプリケーションログの表示
docker compose logs -f web

# webコンテナでコマンド実行
docker compose exec web bash
docker compose exec web rails console
docker compose exec web bundle exec rspec

# データベース操作
docker compose exec web bundle exec ridgepole -c config/database.yml -E development --apply -f db/schemas/Schemafile
```

## 🏗️ ローカル開発セットアップ（Docker無し）

Dockerを使わずにローカルでアプリケーションを実行する場合：

### 1. 依存関係のインストール
```bash
# Ruby依存関係のインストール
bundle install
```

### 2. データベースセットアップ
```bash
# MySQLサーバーを起動（MySQL 8.0+が必要）
# データベース作成とスキーマ適用
bundle exec ridgepole -c config/database.yml -E development --apply -f db/schemas/Schemafile

# 初期データの投入
rails db:seed
```

### 3. サービス起動
```bash
# Railsサーバー起動
rails server

# 別のターミナルでTailwind CSSコンパイル
rails tailwindcss:watch

# またはforemanが利用可能な場合
foreman start -f Procfile.dev
```

## 🛠️ 設定

### 開発環境用の環境変数
`.env.development`ファイルを作成:

```bash
# データベース
DATABASE_URL=mysql2://root@localhost:3306/shlink_ui_rails_development

# Shlink API（実際のShlinkインスタンスでテストする場合）
SHLINK_BASE_URL=http://localhost:8080
SHLINK_API_KEY=your_api_key

# Redis（キャッシュ用、オプション）
REDIS_URL=redis://localhost:6379/0

# メール設定（テスト用）
EMAIL_ADAPTER=letter_opener  # メールがブラウザで開かれる

# OAuth（オプション）
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret

# WebAuthn（セキュリティキーテスト用）
WEBAUTHN_RP_ID=localhost
WEBAUTHN_ORIGIN=http://localhost:3000
```

### 開発環境の機能
- **Letter Opener**: メールが送信される代わりにブラウザで開かれる
- **Tailwind CSS Watch**: CSSの変更が自動的に再コンパイルされる
- **デバッグモード**: 詳細なエラーページとログ
- **テストデータ**: テスト用のサンプルURLとユーザー
- **Importmap**: Node.jsビルドステップなしでモダンJavaScript
- **Hotwire**: Turbo + Stimulusによるリアクティブフロントエンド

## 🧪 テスト

### テストの実行
```bash
# 全テスト
make test

# 特定のテストファイル
docker compose exec web rspec spec/models/user_spec.rb
docker compose exec web rspec spec/system/

# カバレッジ付き
COVERAGE=true make test
```

### テストデータベース
テストでは自動的に作成・管理される別のテストデータベースを使用します。

## 🔍 開発ツール

### デバッグ
- **byebug**: コードに`byebug`を追加してブレークポイント設定
- **Railsコンソール**: `make console` または `rails console`
- **ログ**: `make logs` または `tail -f log/development.log`

### コード品質
- **RuboCop**: `make lint` - Rubyコードスタイルチェッカー
- **Brakeman**: `make security` - セキュリティ脆弱性スキャナー
- **RSpec**: Capybaraを使ったシステムテストを含むテストフレームワーク
- **Ridgepole**: スキーマ管理ツール

## 🆘 トラブルシューティング

### よくある問題

#### ポートが既に使用中
```bash
# ポート3000を使用しているプロセスを確認
lsof -ti:3000
# プロセスを終了
kill -9 <process_id>
```

#### データベース接続問題
```bash
# データベースリセット
docker compose exec web bundle exec ridgepole -c config/database.yml -E development --drop --apply -f db/schemas/Schemafile
docker compose exec web rails db:seed
```

#### パーミッション問題（Linux）
```bash
# ファイル権限修正
sudo chown -R $USER:$USER .
```

#### CSSコンパイル問題
```bash
# CSSリビルド
docker compose exec web rails tailwindcss:build

# またはCSSウォッチサービス再起動
docker compose restart css
```

### ログとデバッグ
```bash
# アプリケーションログ
docker compose logs -f web

# データベースログ
docker compose logs -f db

# 全サービス
docker compose logs -f
```

## 📚 次のステップ

開発環境セットアップ後：

1. **コードを探索**: `app/controllers/`と`app/models/`から始める
2. **設定ガイドを読む**: [設定ガイド](../configuration/settings_ja.md)
3. **デプロイガイドを確認**: [本番デプロイ](../deployment/production_ja.md)
4. **運用ガイドを確認**: [CI/CDシステム](../operations/cd-system_ja.md)

## 🔗 追加リソース

- [メインREADME](../../README_ja.md) - プロジェクト概要と機能
- [English Documentation](development.md) - 英語版開発環境セットアップ
- [本番セットアップ](../deployment/production_ja.md) - 本番デプロイガイド
- [設定ガイド](../configuration/settings_ja.md) - 詳細な設定オプション

---

**サポートが必要ですか？**
- [Issues](https://github.com/enjoydarts/shlink-ui-rails/issues)ページを確認
- 既存の[Pull Requests](https://github.com/enjoydarts/shlink-ui-rails/pulls)をレビュー
- 上記のトラブルシューティングセクションを参照