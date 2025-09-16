# Shlink UI Rails

[Shlink](https://shlink.io/)（セルフホスト型URL短縮サービス）のためのモダンなWebアプリケーション。Ruby on Rails 8で構築され、ユーザーフレンドリーなインターフェースで短縮URLの作成、管理、追跡を可能にします。

## ✨ 機能

### 🔗 URL短縮
- **簡単なURL作成**: 長いURLを短く管理しやすいリンクに変換
- **カスタムスラッグ**: ブランディング用のオプションカスタム短縮コード
- **QRコード生成**: 各短縮URLの自動QRコード作成
- **ワンクリックコピー**: 視覚的フィードバック付きの瞬時クリップボードコピー
- **タグ管理**: カスタムタグによるURL整理・分類機能
- **高度なオプション**: 有効期限、訪問制限、タグ機能への簡単アクセス

### 👤 ユーザー管理・セキュリティ
- **ユーザー認証**: Deviseによる安全な登録・ログインシステム
- **Google OAuth連携**: Googleアカウントでの簡単サインイン
- **メール確認**: 安全なアカウント認証プロセス
- **CAPTCHA保護**: Cloudflare Turnstile によるボット攻撃対策
- **二要素認証（2FA）**: TOTP（RFC 6238）対応の時間ベース認証
- **WebAuthn/FIDO2**: パスワードレス認証・セキュリティキー対応
- **バックアップコード**: 2FA用の使い捨て復旧コード
- **ロールベースアクセス**: 適切な権限を持つ管理者と一般ユーザーロール

### 🔧 管理者パネル機能（NEW!）
- **管理者ダッシュボード**: システム全体統計・サーバーリソース監視・エラー状態チェック
- **独立ログインシステム**: 通常ユーザーとは分離された専用管理者ログイン
- **包括的ユーザー管理**: 全ユーザー一覧・検索・権限変更・アカウント削除機能
- **リアルタイム統計**: 全ユーザーの短縮URL・アクセス状況・システム健康状態
- **動的システム設定**: CAPTCHA・レート制限・メール設定のリアルタイム管理
- **サーバー監視**: メモリ・CPU・ディスク使用率のリアルタイム監視
- **設定テスト機能**: メール設定・CAPTCHA設定のワンクリックテスト
- **直感的な管理UI**: レスポンシブなTailwind CSS設計の専用管理インターフェース

### 📊 マイページダッシュボード
- **個人URLライブラリ**: すべての短縮URLを整理された場所で表示
- **高度な統計ダッシュボード**: Chart.js搭載のインタラクティブな視覚化で包括的な分析
- **全体統計**: Shlink APIからのリアルタイムデータによる総URL数、訪問数、アクティブリンク
- **個別URL分析**: 日別・時間別訪問、ブラウザ統計、国別分布、リファラー分析を含む詳細な統計
- **インタラクティブチャート**: 日別アクセス推移、URLステータス分布、月別作成パターン
- **期間フィルター**: 7日、1ヶ月、3ヶ月、1年の期間で統計表示
- **検索可能URL選択**: タイトル、短縮URL、長いURLによるGmailスタイル検索
- **クイック分析アクセス**: 各URLカードの直接分析ボタンで即座にインサイト表示
- **検索・フィルター**: 内蔵検索機能で特定のURLを素早く検索
- **ページネーション**: 1ページ10URLの整理された表示で簡単ブラウジング
- **リアルタイム同期**: Shlink APIとの手動同期で統計更新
- **URL管理**: 確認ダイアログ付きでリンクの編集、削除、整理
- **タグ表示**: 各URLの整理しやすいタグ視覚化
- **モバイル対応**: モバイルデバイスでの適切なタグ表示配置

### 🎨 モダンUI/UX
- **レスポンシブデザイン**: デスクトップ、タブレット、モバイルで完璧に動作
- **グラスモーフィズムデザイン**: ぼかし効果を持つモダンな半透明インターフェース要素
- **クリーンインターフェース**: 読みやすさとアクセシビリティ向上のため過度なグラデーションを除去
- **スムーズアニメーション**: フェードイン効果とホバーインタラクション
- **ステータスインジケーター**: アクティブ、期限切れ、制限付きURLの視覚的フィードバック
- **モーダルダイアログ**: 破壊的アクションのクリーンな確認ダイアログ
- **タグビジュアライゼーション**: 適切なモバイルレスポンシブ対応の明確なタグデザイン

### 🔧 技術機能
- **Shlink API統合**: 包括的な訪問統計を含むShlink REST API v3との完全統合
- **高度な分析**: 詳細なインサイトのためのShlink訪問エンドポイントとのリアルタイムデータ処理
- **バックグラウンド処理**: Solid Queueでの非同期操作
- **高性能キャッシュ**: 最適な統計レスポンス時間のためのMySQLバックエンドSolid Cache
- **インタラクティブなデータ視覚化**: 動的でレスポンシブなチャートのためのChart.js統合
- **リアルタイム更新**: Shlink APIからのライブデータ同期と更新
- **包括的エラーハンドリング**: ユーザーフレンドリーなエラーメッセージと復旧
- **高度なセキュリティ**: CSRF保護、CAPTCHA、2FA、WebAuthn、暗号化、セキュアヘッダー

## 🛠 技術スタック

### バックエンド
- **Ruby 3.4.5** パフォーマンス向上のためYJIT有効
- **Rails 8.0.2** 最新機能と改善を含む
- **MySQL 8.4** 信頼性とスケーラブルなデータストレージ
- **Devise** 認証とユーザーセッション管理
- **WebAuthn** FIDO2/パスワードレス認証サポート
- **ROTP** RFC 6238準拠のTOTP二要素認証
- **Cloudflare Turnstile** CAPTCHA保護
- **Faraday** ShlinkとのHTTP API通信
- **Ridgepole** データベーススキーマ管理

### フロントエンド
- **Hotwire (Turbo + Stimulus)** SPAライクなインタラクティブ体験
- **Chart.js 4.4.0** インタラクティブでレスポンシブなデータ視覚化
- **Tailwind CSS v4** モダンなユーティリティファーストスタイリング
- **高度なStimulusコントローラー** 統計チャート、個別分析、タブナビゲーション用
- **レスポンシブデザイン** すべてのデバイスタイプに最適化
- **プログレッシブエンハンスメント** アクセシビリティとパフォーマンスの保証

### 開発・テスト
- **RSpec** 包括的な振る舞い駆動テスト
- **RuboCop Rails Omakase** 一貫したコード品質
- **Factory Bot** テストデータ生成
- **WebMock & VCR** 信頼性のあるAPIテスト
- **SimpleCov** テストカバレッジ分析（83.85%カバレッジ）
- **Docker Compose** 一貫した開発環境

## 🚀 クイックスタート

### 前提条件
- Docker と Docker Compose のインストール
- API アクセス権を持つ稼働中の Shlink サーバーインスタンス

### インストール

1. **リポジトリをクローン**
   ```bash
   git clone https://github.com/enjoydarts/shlink-ui-rails.git
   cd shlink-ui-rails
   ```

2. **環境変数をセットアップ**
   ```bash
   cp .env.example .env
   # .env を編集して Shlink API 認証情報を設定
   ```

3. **Shlink設定を構成**
   ```env
   SHLINK_BASE_URL=https://your-shlink-server.com
   SHLINK_API_KEY=your-api-key-here
   GOOGLE_CLIENT_ID=your-google-client-id (オプション)
   GOOGLE_CLIENT_SECRET=your-google-client-secret (オプション)
   TURNSTILE_SITE_KEY=your-turnstile-site-key (オプション)
   TURNSTILE_SECRET_KEY=your-turnstile-secret-key (オプション)
   ```

4. **アプリケーションを開始**
   ```bash
   # Makefileを使用（推奨）
   make setup                    # 初回セットアップ（全て含む）
   make up                       # 2回目以降の起動

   # または Docker Compose を直接使用
   docker-compose up --build     # 初回セットアップ
   docker-compose up             # 2回目以降の起動
   ```

5. **アプリケーションにアクセス**
   - Webインターフェース: http://localhost:3000
   - データベース: port 3307 の MySQL
   - メールプレビュー: http://localhost:3000/letter_opener （開発環境）

## 🚀 本番デプロイ

本番デプロイには複数のオプションをサポートしています：

### 📋 初期セットアップガイド
- **[Setup Guide (English)](SETUP_EN.md)** - 完全な本番セットアップ手順
- **[セットアップガイド (日本語)](SETUP_JA.md)** - 本番環境セットアップ手順

これらのガイドでは、初期管理者アカウント設定、システム設定、メール設定、CAPTCHA、セキュリティ設定をカバーしています。

### 🚢 本番デプロイガイド
- **[Production Deployment Guide (English)](docs/deployment.md)** - OCI/Docker環境での包括的なデプロイ手順
- **[本番デプロイ手順書 (日本語)](docs/deployment_ja.md)** - OCI/Docker環境での詳細なデプロイ手順

**デプロイアーキテクチャ:**
- **サーバー:** OCI Ampere A1 インスタンス（ARM64）
- **Webサーバー:** 自動HTTPS対応のCaddy
- **アプリケーション:** Docker化されたRailsアプリ
- **データベース:** 外部マネージドMySQL
- **キャッシュ:** Upstash Redis
- **CI/CD:** 自動デプロイ対応のGitHub Actions
- **ドメイン:** Cloudflare DNS対応のカスタムドメイン
- **監視:** 包括的なログ記録とヘルスチェック

**主要機能:**
- マルチプラットフォームDockerビルド（AMD64/ARM64）
- GitHub Actionsによる自動化されたCI/CD
- 専用システムユーザーによる安全なデプロイ
- 包括的なバックアップ・監視セットアップ
- 本番対応のセキュリティ設定

## 📱 アプリケーション機能

### ホームページ
- URL短縮フォーム付きのクリーンでモダンなランディングページ
- リアルタイム検証とエラーハンドリング
- タグ管理、有効期限、訪問制限を含む高度なオプション
- 作成されたURLの即座のQRコード生成
- 視覚的フィードバック付きワンクリックコピー機能

### ユーザーダッシュボード（マイページ）
- ユーザーのすべての短縮URLの完全概要
- 高度な検索・フィルタリング機能
- 大きなURLコレクションのページネーション
- 統計表示（総URL数、訪問数、アクティブリンク）
- Shlink APIからデータを更新する手動同期ボタン
- モバイルデバイス向けレスポンシブデザインによるタグ表示
- より良いモバイル体験のための適切なタグ配置

### URL管理
- 個別URLの編集とカスタマイズ
- 複数URLのバルク操作
- 破壊的アクションのモーダル確認ダイアログ
- ステータスインジケーター（アクティブ、期限切れ、訪問制限到達）
- QRコードの表示とダウンロード

## 🔌 API統合

### サポートするShlink APIエンドポイント
- **URL作成**: `POST /rest/v3/short-urls`
- **URL一覧**: `GET /rest/v3/short-urls` （ページネーションと検索付き）
- **URL削除**: `DELETE /rest/v3/short-urls/{shortCode}`
- **QRコード生成**: `GET /rest/v3/short-urls/{shortCode}/qr-code`
- **統計取得**: リアルタイム訪問カウント追跡

### サービスアーキテクチャ
- **Shlink::BaseService**: Faraday HTTPクライアントセットアップ付き基底クラス
- **Shlink::CreateShortUrlService**: 検証付きURL作成処理
- **Shlink::ListShortUrlsService**: フィルタリング付きURL取得管理
- **Shlink::SyncShortUrlsService**: Shlink APIとのユーザーデータ同期
- **Shlink::DeleteShortUrlService**: URL削除操作管理
- **Shlink::GetQrCodeService**: QRコード生成とキャッシュ処理

## 🧪 開発

### Makefileによるクイックコマンド

このプロジェクトには開発を効率化する包括的なMakefileが含まれています：

```bash
# 利用可能なコマンド一覧表示
make help

# 開発ワークフロー
make up                       # サービス起動
make console                 # Railsコンソール開く
make test                    # 全テスト実行
make lint                    # RuboCop実行
make lint-fix                # RuboCop自動修正

# データベース操作
make db-reset                # データベースリセット（作成+マイグレーション）
make db-migrate              # 開発環境マイグレーション実行
make db-migrate-test         # テスト環境マイグレーション実行

# 特定のテストタイプ
make test-system             # システムテストのみ
make test-models             # モデルテストのみ
make test-coverage           # カバレッジレポート付きテスト

# CSS管理
make css-build               # Tailwind CSSビルド
make css-watch               # CSS変更監視

# ユーティリティ
make logs                    # 全サービスログ表示
make clean                   # 一時ファイル削除
make status                  # サービス状況確認
```

### テスト実行
```bash
# Makefileを使用（推奨）
make test                    # 全テスト実行（659例、83.85%カバレッジ）
make test-file FILE=spec/path/to/file_spec.rb  # 特定のテストファイル実行
make test-coverage           # カバレッジレポート付きテスト実行

# Docker Composeを直接使用
docker-compose exec web bundle exec rspec
docker-compose exec web bundle exec rspec spec/path/to/file_spec.rb
docker-compose exec web bundle exec rspec --format documentation
```

### コード品質
```bash
# Makefileを使用（推奨）
make lint                    # RuboCopリンター実行（Rails Omakase設定）
make lint-fix                # 違反の自動修正
make security                # Brakemanによるセキュリティ分析

# Docker Composeを直接使用
docker-compose exec web bundle exec rubocop
docker-compose exec web bundle exec rubocop --autocorrect
docker-compose exec web bundle exec brakeman
```

### データベース操作
```bash
# Makefileを使用（推奨）
make db-reset                # データベース完全リセット
make db-migrate              # Ridgepoleでスキーマ変更適用（開発環境）
make db-migrate-test         # Ridgepoleでスキーマ変更適用（テスト環境）

# Docker Composeを直接使用
docker-compose exec web bundle exec ridgepole -c config/database.yml -E development --apply -f db/schemas/Schemafile
docker-compose exec web bin/rails console
docker-compose exec web bin/rails routes
```

### CSS開発
```bash
# Makefileを使用（推奨）
make css-build               # CSS手動ビルド
make css-watch               # Tailwind CSS変更監視

# Docker Composeを直接使用
docker-compose exec web bin/rails tailwindcss:watch
docker-compose exec web bin/rails tailwindcss:build
```

## 🏗 アーキテクチャ

### セキュリティ機能
- **ユーザー分離**: ユーザーは自分のURLのみアクセス・変更可能
- **CSRF保護**: Rails組み込みのクロスサイトリクエストフォージェリ保護
- **CAPTCHA保護**: Cloudflare Turnstile によるボット攻撃防止
- **二要素認証（2FA）**: TOTP（時間ベース）+ バックアップコード
- **WebAuthn/FIDO2**: パスワードレス認証・ハードウェアセキュリティキー対応
- **暗号化**: 機密データ（2FAシークレット、バックアップコード）のデータベース暗号化
- **入力検証**: ShortenFormオブジェクトでの包括的フォーム検証
- **セキュアヘッダー**: セキュリティ重視のHTTPヘッダー設定
- **認証**: 確認付きDevise駆動ユーザー管理

### パフォーマンス最適化
- **YJIT**: パフォーマンス向上のためのRuby 3.4+ Just-In-Timeコンパイラ
- **キャッシュ**: データベースクエリ最適化のためのSolid Cache
- **バックグラウンドジョブ**: 非同期処理のためのSolid Queue
- **アセットパイプライン**: Propshaftでの最適化されたアセット配信
- **データベースインデックス**: 高速クエリパフォーマンスのための適切なインデックス

### コード構成
```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── short_urls_controller.rb      # URL作成とQRコード
│   ├── mypage_controller.rb          # ユーザーダッシュボードと管理
│   ├── pages_controller.rb           # 静的ページ
│   └── users/
│       └── omniauth_callbacks_controller.rb
├── forms/
│   └── shorten_form.rb               # URL検証フォームオブジェクト
├── models/
│   ├── user.rb                       # DeviseでのUserモデル
│   └── short_url.rb                  # 検証付きShort URLモデル
├── services/shlink/
│   ├── base_service.rb               # HTTPクライアント基盤
│   ├── create_short_url_service.rb   # URL作成ロジック
│   ├── list_short_urls_service.rb    # URL取得とページネーション
│   ├── sync_short_urls_service.rb    # データ同期
│   ├── delete_short_url_service.rb   # URL削除処理
│   └── get_qr_code_service.rb        # QRコード生成
└── views/
    ├── layouts/
    ├── short_urls/
    ├── mypage/
    └── pages/
```

## 🚢 デプロイ

### 本番環境セットアップ
1. **環境設定**
   ```env
   RAILS_ENV=production
   SHLINK_BASE_URL=https://your-production-shlink.com
   SHLINK_API_KEY=your-production-api-key
   DATABASE_URL=mysql2://user:password@host:port/database
   SECRET_KEY_BASE=your-secret-key-base
   ```

2. **アセットコンパイル**
   ```bash
   docker-compose exec web bin/rails assets:precompile
   docker-compose exec web bin/rails tailwindcss:build
   ```

3. **データベースセットアップ**
   ```bash
   # Ridgepoleでデータベーススキーマを適用
   docker-compose exec web bundle exec ridgepole -c config/database.yml -E production --apply -f db/Schemafile
   ```

### Dockerデプロイ
アプリケーションはコンテナ化されており、Docker ComposeやKubernetesでのデプロイ準備が整っています。

## 🤝 コントリビューション

コントリビューションを歓迎します！以下の手順に従ってください：

1. リポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更に対する包括的なテストを記述
4. すべてのテストが通ることを確認 (`bundle exec rspec`)
5. RuboCopを実行し問題を修正 (`bundle exec rubocop`)
6. 変更をコミット (`git commit -m 'Add amazing feature'`)
7. ブランチにプッシュ (`git push origin feature/amazing-feature`)
8. 詳細な説明付きでプルリクエストを開く

### 開発ガイドライン
- Railsの慣例とベストプラクティスに従う
- テストカバレッジを80%以上に維持（現在83.85%）
- RuboCop Rails Omakase設定を使用
- 明確で説明的なコミットメッセージを記述
- 新機能についてはドキュメントを更新
- セキュリティ機能（CAPTCHA、2FA、WebAuthn）のテストを包括的に実装

## 🆘 トラブルシューティング

### よくある問題

**CSSが更新されない？**
```bash
# Tailwind CSSを再ビルド
docker-compose exec web bin/rails tailwindcss:build
```

**データベース接続エラー？**
```bash
# データベースコンテナステータス確認
docker-compose ps db
# データベースログ表示
docker-compose logs db
```

**Shlink APIエラー？**
- `.env`の`SHLINK_BASE_URL`と`SHLINK_API_KEY`を確認
- Shlinkサーバーのアクセス可能性をチェック
- アプリケーションログを確認: `docker-compose logs web`

**JavaScriptが動作しない？**
```bash
# importmapステータス確認
docker-compose exec web bin/rails importmap:outdated
```

### パフォーマンスのヒント
- 最適なパフォーマンスのためRubyログでYJITステータスを監視
- ブラウザ開発者ツールを使用して未使用CSSクラスを特定
- より良いユーザー体験のためHotwireキャッシュを活用

## 📄 ライセンス

このプロジェクトはMITライセンスの下でライセンスされています - 詳細は [LICENSE](LICENSE) ファイルを参照してください。

## 🙏 謝辞

- [Shlink](https://shlink.io/) - 強力なセルフホスト型URL短縮サービス
- [Ruby on Rails](https://rubyonrails.org/) - 堅牢なWebアプリケーションフレームワーク
- [Tailwind CSS](https://tailwindcss.com/) - ユーティリティファーストCSSフレームワーク
- [Hotwire](https://hotwired.dev/) - Webアプリケーション構築への現代的アプローチ
- [Devise](https://github.com/heartcombo/devise) - 柔軟な認証ソリューション

---

Ruby on Rails で ❤️ を込めて構築

**作成者**: enjoydarts
**最終更新**: 2025年9月16日
**バージョン**: 1.2.0

## 🎯 実装済み機能一覧

### 基本機能
- ✅ URL短縮作成
- ✅ カスタムスラッグ設定
- ✅ QRコード自動生成
- ✅ ワンクリックコピー
- ✅ タグ管理機能（高度なオプション）
- ✅ 有効期限・訪問制限設定

### ユーザー管理・セキュリティ
- ✅ ユーザー登録・ログイン
- ✅ Google OAuth連携
- ✅ メール確認機能
- ✅ ロールベースアクセス制御
- ✅ Cloudflare Turnstile CAPTCHA保護
- ✅ TOTP二要素認証（QRコード生成、バックアップコード）
- ✅ WebAuthn/FIDO2セキュリティキー対応
- ✅ 機密データの暗号化（2FAシークレット、バックアップコード）

### 管理者パネル機能
- ✅ システム統計付き管理者ダッシュボード
- ✅ 独立管理者ログインシステム
- ✅ 包括的ユーザー管理
- ✅ リアルタイムシステム監視
- ✅ 動的システム設定
- ✅ 設定テスト機能
- ✅ バックグラウンドジョブ監視
- ✅ サーバーリソース監視
- ✅ 管理者専用アクセス制御

### マイページ機能
- ✅ 個人URL一覧表示
- ✅ 検索・フィルタリング
- ✅ ページネーション（10件/ページ）
- ✅ 統計情報表示
- ✅ Shlink API同期
- ✅ URL削除機能（モーダル確認付き）
- ✅ タグ表示・視覚化
- ✅ モバイル対応タグレイアウト

### UI/UX
- ✅ レスポンシブデザイン
- ✅ グラスモーフィズムUI
- ✅ スムーズアニメーション
- ✅ ステータスバッジ
- ✅ モーダルダイアログ
- ✅ クリーンインターフェース（グラデーション調整）
- ✅ タグの視覚的デザイン

### 技術機能
- ✅ Rails 8.0 + Hotwire
- ✅ Tailwind CSS v4
- ✅ MySQL 8.4
- ✅ Docker環境
- ✅ 包括的テスト（80.8%以上カバレッジ、1010例ALL GREEN）
- ✅ RuboCop品質管理
- ✅ CI/CD GitHub Actions
- ✅ 高度なセキュリティ対策（CAPTCHA、2FA、WebAuthn）
