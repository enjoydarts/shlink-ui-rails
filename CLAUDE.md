# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリでコードを扱う際のガイダンスを提供します。

## 開発コマンド

### Docker ベース開発
すべての開発は Docker コンテナ内で行います：

```bash
# 全サービス開始（初回ビルド付き）
docker-compose up --build

# サービス開始（2回目以降）
docker-compose up

# コンテナ内でRailsコマンド実行
docker-compose exec web bin/rails console
docker-compose exec web bin/rails routes

# データベース操作（Ridgepole使用）
docker-compose exec web bin/rails db:create
docker-compose exec web bundle exec ridgepole -c config/database.yml -E development --apply -f db/schemas/Schemafile
docker-compose exec web bundle exec ridgepole -c config/database.yml -E test --apply -f db/schemas/Schemafile

# CSSビルド（通常はcssサービスで自動実行）
docker-compose exec web bin/rails tailwindcss:build
docker-compose exec web bin/rails tailwindcss:watch

# ログ確認
docker-compose logs -f web
docker-compose logs -f css
```

### テストと品質管理
```bash
# 全テスト実行（RSpec）
docker-compose exec web bundle exec rspec

# 特定のテストファイル実行
docker-compose exec web bundle exec rspec spec/path/to/file_spec.rb

# Lint実行（RuboCop with Rails Omakase）
docker-compose exec web bundle exec rubocop

# セキュリティチェック
docker-compose exec web bundle exec brakeman
```

## アーキテクチャ概要

### コアサービスアーキテクチャ
Shlink API とのやり取り専用サービスクラスを持つサービス指向アーキテクチャ：

- **Shlink::BaseService** (`app/services/shlink/base_service.rb`): Faradayを使ったHTTPクライアント設定、エラーハンドリング、認証ヘッダーを提供するベースクラス
- **Shlink::CreateShortUrlService** (`app/services/shlink/create_short_url_service.rb`): Shlink API `/rest/v3/short-urls` エンドポイント経由でURL短縮を処理
- **Shlink::GetQrCodeService** (`app/services/shlink/get_qr_code_service.rb`): 短縮URLのQRコード生成を処理

### フォームオブジェクト
- **ShortenForm** (`app/forms/shorten_form.rb`): URL短縮用のActiveModelフォームオブジェクト、URL形式の検証と任意のslug/QRコードパラメータ付き

### フロントエンドアーキテクチャ
- **Hotwire Stack**: JavaScript フレームワークなしでSPAライクな体験を提供するTurbo + Stimulus
- **Tailwind CSS v4**: グラスモーフィズムデザインのモダンなユーティリティファーストCSS
- **Stimulus Controllers**: 
  - `clipboard_controller.js`: ワンクリックコピー機能
  - `submitter_controller.js`: フォーム送信処理
  - `tag_input_controller.js`: Gmail風タグ入力UI（入力フィールド内タグ表示、バリデーション付き）
  - `accordion_controller.js`: 高度なオプション展開/収納

### API統合
Shlink API用の環境ベース設定：
- `SHLINK_BASE_URL`: ShlinkサーバーURL
- `SHLINK_API_KEY`: API認証キー

エラーハンドリングには適切なHTTPステータスコード処理とユーザーフレンドリーなエラーメッセージを含みます。

## 開発環境

### 技術スタック
- YJIT有効化のRuby 3.4.5
- Rails 8.0.2.1
- MySQL 8.4 データベース
- コンテナ化のためのDocker Compose
- フロントエンドインタラクティブ用のHotwire（Turbo + Stimulus）
- スタイリング用のTailwind CSS v4

### 主要依存関係
- `faraday` + `faraday_middleware`: API通信用HTTPクライアント
- `rspec-rails`: テストフレームワーク（Test::Unitではない）
- `rubocop-rails-omakase`: コードスタイル強制
- `capybara` + `selenium-webdriver`: システムテスト

### 開発サービス
Docker Composeは3つのサービスを実行：
1. **web**: Railsアプリケーションサーバー（ポート3000）
2. **css**: 自動リビルド用のTailwind CSSファイルウォッチャー
3. **db**: MySQLデータベース（ポート3307）

### テスト設定
以下を使用するRSpec：
- テストデータ生成用のFactoryBot
- HTTPリクエストスタブ用のWebMock
- HTTPインタラクション記録用のVCR
- Rails固有のアサーション用のShouldaマッチャー
- カバレッジレポート用のSimpleCov
- システム/統合テスト用のCapybara

## コードパターン

### サービスクラスパターン
すべてのShlink APIとのやり取りは`Shlink::BaseService`を継承するサービスクラスを使用。サービスは以下のパターンに従う：
- メイン機能用の`call`メソッド
- 例外発生版の`call!`メソッド
- リクエスト構築とレスポンス処理用のプライベートメソッド

### エラーハンドリング
APIレスポンスからの詳細エラーメッセージ抽出を持つAPIエラー用のカスタム`Shlink::Error`例外クラス。

### フォームオブジェクト
ActiveModelベースのフォームオブジェクトは適切な検証と属性処理でモデルからフォームロジックを分離。

## モバイル対応とブラウザサポート

### ブラウザ互換性
`ApplicationController`で以下のブラウザバージョンをサポート：
- Safari 12+
- Chrome 70+
- Firefox 70+
- Edge 79+
- Opera 57+

これにより、モバイルブラウザからの正常なアクセスが可能。

### レスポンシブデザイン
- Tailwind CSSのモバイルファーストアプローチ
- `min-w-[120px]`など、フレキシブルな最小幅設定
- `flex-wrap`による要素の適応的配置
- タッチ操作に適したボタンサイズ（`p-1`以上）

## 最近の改善

### タグ入力UI改善（2025年1月実装）
- Gmail風インライン表示：タグが入力フィールド内に表示
- リアルタイムバリデーション：文字数制限、重複チェック、最大個数制限
- キーボードナビゲーション：Enterキーでの追加、ESCキーでのクリア
- 視覚的フィードバック：フォーカス状態の強調、エラー時の境界色変更