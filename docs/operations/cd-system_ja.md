# 🚀 CI/CDシステム ドキュメント

このドキュメントでは、Shlink-UI-RailsのGitHub Actionsを使用した継続的デプロイ（CD）システムについて説明します。

## 📋 システム概要

CDシステムは、mainブランチへのプッシュをトリガーとして、テスト実行、デプロイ、ヘルスチェック、失敗時の自動ロールバックまでを自動化します。

```
GitHub Repository (main branch)
       ↓ push trigger
GitHub Actions Workflow
       ├── 事前チェック
       ├── テスト実行
       ├── Dockerイメージビルド・プッシュ
       ├── 本番デプロイ
       ├── ヘルスチェック・検証
       └── 通知
```

## 🔧 ワークフローコンポーネント

### 1. 事前チェック

**目的**: デプロイの実行可否を判断

**処理内容**:
- コミットメッセージに `[skip deploy]` が含まれていないかチェック
- 手動実行時のテストスキップ設定を確認
- デプロイ実行フラグを他ジョブに渡す

**スキップ条件**:
- コミットメッセージに `[skip deploy]` が含まれている場合

### 2. テスト実行

**目的**: コードの品質とテストを検証

**処理内容**:
- MySQLとRedisサービスコンテナの起動
- Ruby環境のセットアップ
- データベースのセットアップ
- RuboCopによるコード品質チェック
- RSpecテストの実行

**スキップ条件**:
- 事前チェックでスキップフラグが設定されている場合
- 手動実行時にテストスキップが指定された場合（緊急デプロイ）

### 3. Dockerイメージビルド・プッシュ

**目的**: Dockerイメージのビルドと公開

**処理内容**:
- マルチステージDockerイメージのビルド
- コミットSHAと'latest'でのタグ付け
- GitHub Container Registry (ghcr.io) へのプッシュ
- 高速ビルドのためのレイヤーキャッシュ

**レジストリ**: `ghcr.io/yourusername/shlink-ui-rails`

### 4. 本番デプロイ

**目的**: 本番サーバーへのアプリケーションデプロイ

**処理内容**:
- SSH経由での本番サーバー接続
- 最新Dockerイメージの取得
- 環境設定の更新
- データベースマイグレーションの実行（Ridgepole）
- アプリケーションサービスの再起動
- コンテナ起動の検証

**対象サーバー**: `yourdomain.com`

### 5. ヘルスチェック・検証

**目的**: デプロイ成功の確認

**処理内容**:
- HTTPヘルスエンドポイントチェック（`/health`）
- データベース接続の確認
- サービス可用性の確認
- レスポンス時間の検証

**リトライロジック**:
- 最大10回試行
- 30秒間隔
- 失敗時の自動ロールバック

### 6. デプロイ後通知

**目的**: チームへのデプロイ結果通知

**対応チャンネル**:
- Slack通知
- Discord通知
- メール通知

## 🔑 必要なシークレット

GitHubリポジトリの設定で以下のシークレットを設定してください：

### デプロイメントシークレット
| シークレット名 | 説明 |
|--------------|------|
| `DEPLOY_HOST` | 本番サーバーのIPアドレス |
| `DEPLOY_USER` | 本番サーバーのSSHユーザー名 |
| `DEPLOY_KEY` | サーバーアクセス用のSSH秘密鍵 |
| `PRODUCTION_ENV` | 完全な`.env.production`ファイルの内容 |

### 通知シークレット（オプション）
| シークレット名 | 説明 |
|--------------|------|
| `SLACK_WEBHOOK_URL` | Slack通知用のwebhook URL |
| `DISCORD_WEBHOOK_URL` | Discord通知用のwebhook URL |
| `NOTIFICATION_EMAIL` | 通知用のメールアドレス |

## 🎛️ ワークフロー設定

### 自動トリガー

**mainブランチプッシュ**:
```yaml
on:
  push:
    branches: [ main ]
```

**手動トリガー**:
```yaml
on:
  workflow_dispatch:
    inputs:
      skip_tests:
        description: 'テストをスキップ（緊急デプロイ）'
        required: false
        default: false
        type: boolean
```

### 環境変数

**本番環境**:
- `RAILS_ENV=production`
- `DOCKER_DEFAULT_PLATFORM=linux/amd64`
- `PRODUCTION_ENV`シークレットからのカスタム環境

## 🛡️ 安全機能

### デプロイ前チェック
- 包括的テストスイートの実行
- コード品質検証（RuboCop）
- セキュリティスキャン（Brakeman）
- データベースマイグレーションのドライラン

### ロールバック機能
- ヘルスチェック失敗時の自動ロールバック
- 前バージョンイメージの保持
- データベースマイグレーションのロールバック機能
- サービス復旧手順

### ブルーグリーンデプロイメント風
- ゼロダウンタイムデプロイ戦略
- トラフィックルーティング前のヘルスチェック
- 段階的サービス再起動

## 📊 監視統合

### ヘルスエンドポイント
```bash
# アプリケーションヘルス
GET /health

# データベースヘルス
GET /health/database

# Redisヘルス
GET /health/redis
```

### メトリクス収集
- デプロイ頻度の追跡
- 成功/失敗率
- ロールバック頻度
- デプロイ所要時間メトリクス

## 🔧 手動デプロイ

### 緊急デプロイ
テストをスキップする緊急デプロイの場合：

1. GitHub Actionsタブに移動
2. "Deploy to Production"ワークフローを選択
3. "Run workflow"をクリック
4. "Skip tests (emergency deployment)"をチェック
5. "Run workflow"をクリック

### 手動ロールバック
```bash
# 本番サーバーにSSH接続
ssh user@yourdomain.com

# 前バージョンにロールバック
docker-compose -f docker-compose.prod.yml down
docker tag ghcr.io/yourusername/shlink-ui-rails:previous ghcr.io/yourusername/shlink-ui-rails:latest
docker-compose -f docker-compose.prod.yml up -d

# ロールバック確認
docker-compose logs -f app
```

## 🐛 トラブルシューティング

### よくある問題

#### ヘルスチェックでデプロイが失敗
```bash
# アプリケーションログ確認
docker-compose logs app

# コンテナステータス確認
docker-compose ps

# 手動ヘルスチェック
curl -f https://yourdomain.com/health
```

#### SSH接続問題
```bash
# SSH鍵の確認
ssh -i path/to/key user@server

# サーバーSSH設定確認
sudo systemctl status ssh
```

#### Dockerビルド失敗
```bash
# GitHub Actionsでビルドログをチェック
# Dockerfileの変更をレビュー
# ベースイメージの可用性を確認
```

#### データベースマイグレーション失敗
```bash
# マイグレーション状態確認
bundle exec ridgepole -c config/database.yml -E production --dry-run -f db/schemas/Schemafile

# 手動マイグレーション
bundle exec ridgepole -c config/database.yml -E production --apply -f db/schemas/Schemafile
```

### デバッグコマンド

#### デプロイメント状態
```bash
# 実行中コンテナ確認
docker ps

# デプロイログ表示
journalctl -u docker -f

# アプリケーションヘルス確認
curl -i https://yourdomain.com/health
```

#### パフォーマンス監視
```bash
# リソース使用量
docker stats

# アプリケーションメトリクス
docker exec app rails runner "puts Rails.cache.stats"

# データベースパフォーマンス
docker exec app rails dbconsole -c "SHOW PROCESSLIST;"
```

## 📈 パフォーマンス最適化

### ビルド最適化
- マルチステージDockerビルド
- レイヤーキャッシュ
- 最小限のベースイメージ
- アセットプリコンパイル

### デプロイ速度
- 並列ジョブ実行
- 増分更新
- スマートキャッシュ無効化
- 最適化されたヘルスチェック

## 🔗 関連ドキュメント

- [本番デプロイガイド](../deployment/production_ja.md) - 手動デプロイ手順
- [監視ガイド](monitoring_ja.md) - アプリケーション監視・アラート
- [設定ガイド](../configuration/settings_ja.md) - 環境設定
- [English Documentation](cd-system.md) - English CI/CD documentation

## 📞 サポート

CI/CDの問題については：
1. GitHub Actionsログで詳細なエラーメッセージを確認
2. 上記のトラブルシューティングセクションをレビュー
3. 必要なシークレットがすべて設定されていることを確認
4. サーバー接続とリソースを確認
5. [GitHub Issues](https://github.com/enjoydarts/shlink-ui-rails/issues)をレビュー

---

**注意**: このシステムは高い信頼性を目的として設計されており、複数の安全機構を含んでいます。本番デプロイ前には必ず変更内容を十分にテストしてください。