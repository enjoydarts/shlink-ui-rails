# Shlink UI Rails

<img width="1920" height="793" alt="localhost_3000_account" src="https://github.com/user-attachments/assets/b74e1bba-c9fe-4c89-b8c9-41f1910088d8" />

[Shlink](https://shlink.io/)（セルフホスト型URL短縮サービス）のためのモダンなWebアプリケーション。Ruby on Rails 8で構築され、ユーザーフレンドリーなインターフェースで短縮URLの作成、管理、追跡を可能にします。

## ✨ 機能

### 🔗 URL管理
- **簡単なURL作成**: 長いURLを短く管理しやすいリンクに変換
- **カスタムスラッグ**: ブランディング用のオプションカスタム短縮コード
- **QRコード生成**: 各短縮URLの自動QRコード作成
- **高度なオプション**: 有効期限、訪問制限、タグ付け機能
- **一括操作**: 複数URLの効率的な管理

### 👤 ユーザーエクスペリエンス
- **直感的なダッシュボード**: 全デバイス対応のクリーンで響式インターフェース
- **リアルタイム分析**: 包括的な訪問統計と洞察
- **スマート検索**: URL、タイトル、タグ全体でのGmailスタイル検索
- **モバイルファースト設計**: スマートフォン、タブレット、デスクトップでのシームレスな体験

### 🔐 セキュリティ・認証
- **多要素認証**: TOTP（アプリベース）+ WebAuthn/FIDO2セキュリティキー
- **OAuth連携**: インテリジェントな2FA処理を備えたGoogle Sign-In
- **ロールベースアクセス**: 適切な権限を持つユーザーと管理者ロール
- **CAPTCHA保護**: スパム防止のためのCloudflare Turnstile連携
- **レート制限**: APIと認証エンドポイントの設定可能な制限

### 🛡️ 管理者機能
- **システムダッシュボード**: リアルタイム監視と統計
- **ユーザー管理**: 包括的なユーザー管理ツール
- **動的設定**: 再起動不要のライブシステム設定
- **バックグラウンドジョブ監視**: SolidQueueジョブの追跡と管理
- **ヘルス監視**: システムリソースとサービスヘルスチェック

## 🛠 技術スタック

**バックエンド:**
- Ruby 3.4.5 + Rails 8.0.2
- MySQL 8.4（Ridgepoleによるスキーマ管理）
- Redis（キャッシュとセッション）
- SolidQueue（バックグラウンドジョブ）

**フロントエンド:**
- Hotwire（Turbo + Stimulus）によるリアクティブインタラクション
- Tailwind CSS 4 によるスタイリング
- ビルドステップ不要のモダンJavaScript（Importmap）

**インフラストラクチャ:**
- Docker Compose（開発・本番環境）
- Caddy（リバースプロキシとSSL終端）
- GitHub Actions（CI/CD）

## 🚀 クイックスタート

### 開発環境セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/enjoydarts/shlink-ui-rails.git
cd shlink-ui-rails

# Docker使用（推奨）
make setup
# これにより：サービス開始、データベース設定、シードデータ作成

# アプリケーションにアクセス
open http://localhost:3000
```

**デフォルト認証情報:**
- メールアドレス: `admin@example.com`
- パスワード: `password`

### 基本コマンド
```bash
make up        # サービス開始
make down      # サービス停止
make test      # テスト実行（RSpec）
make lint      # コード品質チェック（RuboCop）
make console   # Railsコンソール
```

## 🚢 本番デプロイ

**クイック本番セットアップ:**
```bash
# 環境設定
cp .env.example .env.production
# .env.productionをあなたの設定で編集

# Docker Composeでデプロイ
docker-compose -f docker-compose.prod.yml up -d
```

**主要要件:**
- 外部MySQLデータベース
- Redisインスタンス
- SSL付きドメイン（Caddyで自動）
- メール用のSMTPまたはMailerSend

## 📚 ドキュメント

包括的なガイドが `/docs` ディレクトリに用意されています：

- **[開発環境セットアップ](docs/setup/development_ja.md)** - 完全な開発環境ガイド
- **[本番デプロイメント](docs/deployment/production_ja.md)** - 本番デプロイと設定
- **[設定ガイド](docs/configuration/settings_ja.md)** - 詳細な設定オプション
- **[CI/CDシステム](docs/operations/cd-system_ja.md)** - 自動デプロイとテスト
- **[監視ガイド](docs/operations/monitoring_ja.md)** - アプリケーション監視とアラート

**English documentation** も全ガイドで利用可能です。

## 🔌 API連携

Shlink REST API v3との連携機能:
- URL作成、編集、削除
- 訪問統計と分析
- QRコード生成
- 一括操作と同期

## 🤝 コントリビューション

1. リポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更を行う
4. テストを実行: `make test && make lint`
5. 変更をコミット (`git commit -m 'Add amazing feature'`)
6. ブランチにプッシュ (`git push origin feature/amazing-feature`)
7. プルリクエストを作成

## 📄 ライセンス

このプロジェクトはMITライセンスの下でライセンスされています - 詳細は [LICENSE](LICENSE) ファイルを参照してください。

## 🙏 謝辞

- [Shlink](https://shlink.io/) - 強力なセルフホスト型URL短縮サービス
- [Ruby on Rails](https://rubyonrails.org/) - 堅牢なWebアプリケーションフレームワーク
- [Tailwind CSS](https://tailwindcss.com/) - ユーティリティファーストCSSフレームワーク
- [Hotwire](https://hotwired.dev/) - Webアプリケーション構築への現代的アプローチ

---

Ruby on Rails で ❤️ を込めて構築

**作成者**: enjoydarts
**バージョン**: 1.2.0