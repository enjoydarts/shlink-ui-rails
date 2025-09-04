# Shlink UI Rails

モダンなUI/UXを備えたURL短縮Webアプリケーション。[Shlink](https://shlink.io/)をバックエンドAPIとして使用し、Rails 8 + Hotwire + Tailwind CSSで構築されています。

## ✨ 特徴

- 🚀 **高速**: Rails 8 + YJIT による高速処理
- 🎨 **モダンUI**: Tailwind CSS によるレスポンシブデザイン
- ⚡ **リアルタイム**: Hotwire (Turbo + Stimulus) によるSPA体験
- 🔗 **URL短縮**: Shlink API統合による確実な短縮URL生成
- 📱 **レスポンシブ**: モバイル・デスクトップ対応
- 🎯 **カスタマイズ**: 自由なスラッグ設定
- 📋 **ワンクリックコピー**: 生成されたURLの簡単コピー

## 🛠 技術スタック

- **フレームワーク**: Ruby on Rails 8.0.2.1
- **フロントエンド**: Hotwire (Turbo + Stimulus)
- **CSS**: Tailwind CSS v4.1.12
- **データベース**: MySQL 8.4
- **Ruby**: 3.4.5 (YJIT有効)
- **コンテナ**: Docker + Docker Compose

## 📋 前提条件

- Docker & Docker Compose
- Shlinkサーバー（API アクセス）

## 🚀 セットアップ

### 1. リポジトリをクローン

```bash
git clone https://github.com/your-username/shlink-ui-rails.git
cd shlink-ui-rails
```

### 2. 環境変数を設定

`.env` ファイルを編集してShlinkサーバーの情報を設定：

```bash
# Shlink API設定
SHLINK_BASE_URL=https://your-shlink-domain.com
SHLINK_API_KEY=your-api-key-here

# データベース設定（通常は変更不要）
DATABASE_HOST=db
DATABASE_NAME=shlink_ui_rails_development
DATABASE_USER=app
DATABASE_PASSWORD=apppass
```

### 3. アプリケーションを起動

```bash
# 初回ビルド & 起動
docker-compose up --build

# 2回目以降
docker-compose up
```

### 4. データベースセットアップ

別のターミナルで：

```bash
# データベース作成
docker-compose exec web bin/rails db:create

# マイグレーション実行
docker-compose exec web bin/rails db:migrate
```

### 5. アプリケーションにアクセス

ブラウザで http://localhost:3000 を開く

## 🔧 開発

### 開発サーバーについて

Docker Compose起動時に以下のサービスが自動起動：

- **web**: Rails サーバー (port 3000)
- **css**: Tailwind CSS ウォッチャー（ファイル変更時自動ビルド）
- **db**: MySQL データベース (port 3307)

### ファイル変更時の自動リロード

- **CSS/HTML変更**: Tailwindが自動リビルド
- **Ruby/Rails変更**: アプリケーションが自動リロード
- **JavaScript変更**: Hotwireが自動反映

### よく使うコマンド

```bash
# コンテナ内でRailsコマンド実行
docker-compose exec web bin/rails console
docker-compose exec web bin/rails routes
docker-compose exec web bin/rails db:migrate

# Tailwind手動ビルド（通常は不要）
docker-compose exec web bin/rails tailwindcss:build

# テスト実行
docker-compose exec web bin/rails test

# ログ確認
docker-compose logs -f web
docker-compose logs -f css
```

## 📁 プロジェクト構造

```
.
├── app/
│   ├── controllers/        # コントローラー
│   │   └── short_urls_controller.rb
│   ├── forms/             # フォームオブジェクト
│   │   └── shorten_form.rb
│   ├── javascript/        # Stimulus コントローラー
│   │   └── controllers/
│   │       ├── clipboard_controller.js
│   │       └── submitter_controller.js
│   ├── services/          # サービスクラス
│   │   └── shlink.rb      # Shlink API クライアント
│   └── views/
│       ├── layouts/
│       └── short_urls/
├── config/
│   ├── routes.rb          # ルーティング設定
│   └── importmap.rb       # JavaScript インポートマップ
├── compose.yaml           # Docker Compose設定
├── Procfile.dev          # 開発プロセス設定
└── .env                  # 環境変数
```

## 🎨 UI/UX 機能

### デザイン特徴

- **グラスモーフィズム**: 半透明の背景とぼかし効果
- **グラデーション**: 美しい色の遷移
- **アニメーション**: スムーズなフェードイン効果
- **ホバーエフェクト**: インタラクティブな要素
- **状態フィードバック**: 成功・エラー・ローディング状態の視覚表現

### アクセシビリティ

- キーボードナビゲーション対応
- 色とアイコンによる状態表現
- スクリーンリーダー対応
- 適切なコントラスト比

## 🔌 API連携

### Shlink APIクライアント

`app/services/shlink.rb` でShlink APIとの通信を管理：

- **認証**: API キーによる認証
- **エラーハンドリング**: 適切なエラー処理
- **レスポンス処理**: JSONレスポンスの解析

### 対応エンドポイント

- `POST /rest/v3/short-urls` - URL短縮

## 🧪 テスト

```bash
# 全テスト実行
docker-compose exec web bin/rails test

# 特定のテスト実行
docker-compose exec web bin/rails test test/controllers/short_urls_controller_test.rb
```

## 🚀 デプロイ

### 本番環境での注意点

1. **環境変数設定**
   ```bash
   RAILS_ENV=production
   SHLINK_BASE_URL=https://your-production-shlink.com
   SHLINK_API_KEY=your-production-api-key
   ```

2. **アセットプリコンパイル**
   ```bash
   docker-compose exec web bin/rails assets:precompile
   docker-compose exec web bin/rails tailwindcss:build
   ```

3. **データベース**
   ```bash
   docker-compose exec web bin/rails db:create RAILS_ENV=production
   docker-compose exec web bin/rails db:migrate RAILS_ENV=production
   ```

## 🤝 コントリビューション

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## 📝 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。

## 🆘 トラブルシューティング

### よくある問題

**Q: CSSが反映されない**
```bash
# Tailwindを手動リビルド
docker-compose exec web bin/rails tailwindcss:build
```

**Q: データベース接続エラー**
```bash
# データベースコンテナの状態確認
docker-compose ps db
# ヘルスチェック確認
docker-compose logs db
```

**Q: JavaScriptエラー**
```bash
# importmap確認
docker-compose exec web bin/rails importmap:outdated
```

### パフォーマンス最適化

- YJITが有効化されているかRubyログで確認
- Tailwind CSSの未使用クラス削除
- Hotwireキャッシュの活用

---

**作成者**: enjoydarts
**最終更新**: 2025年9月
**バージョン**: 0.0.1
