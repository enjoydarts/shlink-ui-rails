# 継続的デプロイ（CD）システム ドキュメント

## 概要

本プロジェクトのCD（Continuous Deployment）システムは、GitHub Actionsを使用して本番環境への自動デプロイを実現しています。mainブランチへのプッシュをトリガーに、テスト実行からデプロイ、ヘルスチェックまでを自動化し、問題発生時の自動ロールバック機能も提供します。

## システム構成

```
GitHub Repository (main branch)
       ↓ push trigger
GitHub Actions Workflow
       ├── Pre-checks
       ├── Test Execution
       ├── Docker Image Build & Push
       ├── Production Deployment
       ├── Health Check & Verification
       └── Notification
```

## ワークフロー詳細

### 1. 事前チェック（pre-checks）

**目的**: デプロイの可否を判断する

**処理内容**:
- コミットメッセージに `[skip deploy]` が含まれていないかチェック
- 手動実行時のテストスキップ設定を確認
- デプロイ実行フラグを他ジョブに渡す

**スキップ条件**:
- コミットメッセージに `[skip deploy]` が含まれている場合

### 2. テスト実行（test）

**目的**: コードの品質とテストを確認

**処理内容**:
- MySQL・Redisサービスコンテナの起動
- Ruby環境とNode.js環境のセットアップ
- データベースのセットアップ
- RuboCopによるコード品質チェック
- RSpecテストの実行

**スキップ条件**:
- 事前チェックでスキップフラグが設定されている場合
- 手動実行時にテストスキップが指定された場合（緊急デプロイ）

### 3. Dockerイメージビルド・プッシュ（build-and-push）

**目的**: 本番用Dockerイメージの作成と配布

**処理内容**:
- GitHub Container Registry（ghcr.io）へのログイン
- Dockerイメージのメタデータ抽出
- ARM64アーキテクチャ用イメージのビルド（OCI Ampere A1対応）
- イメージのプッシュ
- キャッシュを活用した高速化

**出力**:
- イメージURL
- イメージダイジェスト
- タグ情報

### 4. 本番デプロイ（deploy）

**目的**: 本番環境への安全なデプロイ実行

**処理内容**:
1. **SSH接続の準備**
   - SSH鍵の設定
   - known_hostsの更新

2. **デプロイスクリプトの作成**
   - 動的にデプロイスクリプトを生成
   - エラーハンドリング・ロールバック機能付き

3. **本番サーバーでの処理**:
   - 最新コードの取得
   - 環境変数ファイルの確認
   - コンテナレジストリへのログイン
   - 現在のコンテナをバックアップ
   - 新しいDockerイメージのプル
   - データベースマイグレーションの実行
   - システム設定の初期化
   - ゼロダウンタイムでのサービス再起動
   - ヘルスチェックの実行
   - 失敗時の自動ロールバック

### 5. 外部アクセス検証（verify-external-access）

**目的**: 外部からアプリケーションにアクセス可能か確認

**処理内容**:
- 外部URL（https://app.kety.at/health）でのヘルスチェック
- タイムアウト時間: 5分
- 15秒間隔での再試行

### 6. デプロイ後検証（post-deployment-checks）

**目的**: デプロイの完全性を検証

**処理内容**:
- 基本ヘルスチェック
- SSL証明書の有効期限確認
- セキュリティヘッダーの存在確認

### 7. 通知（notify）

**目的**: デプロイ結果の通知とサマリー作成

**処理内容**:
- 成功時の通知メッセージ
- 失敗時の詳細エラー情報
- GitHubのStep Summaryにデプロイサマリーを出力

## 手動操作オプション

### 手動実行

GitHub ActionsのUIから手動でワークフローを実行可能：

```
Repository → Actions → Production Deployment → Run workflow
```

**オプション**:
- `skip_tests`: テストをスキップして緊急デプロイを実行

### デプロイスキップ

コミットメッセージに `[skip deploy]` を含めることでデプロイをスキップ可能：

```bash
git commit -m "docs: update documentation [skip deploy]"
```

## ロールバック機能

### 自動ロールバック

デプロイ中にヘルスチェックが失敗した場合、自動的にロールバックが実行されます。

**条件**:
- ヘルスチェックのタイムアウト（5分）
- アプリケーションが正常に起動しない場合

**処理**:
1. バックアップイメージの確認
2. バックアップイメージのタグ付け
3. サービスの再起動
4. ヘルスチェックの実行

### 手動ロールバック

`scripts/rollback.sh` スクリプトを使用して手動でロールバックを実行可能：

```bash
# 利用可能なバックアップの確認
./scripts/rollback.sh -l

# 特定のバックアップにロールバック
./scripts/rollback.sh backup-20240316-143022

# 最新のバックアップにロールバック
./scripts/rollback.sh

# ドライランモード（実行せずに確認のみ）
./scripts/rollback.sh --dry-run backup-20240316-143022
```

## 必要なGitHub Secrets

CDシステムを動作させるために以下のSecretを設定する必要があります：

| Secret名 | 説明 | 例 |
|---------|------|-----|
| `OCI_HOST` | OCIインスタンスのパブリックIP | `123.456.789.0` |
| `OCI_USERNAME` | SSH接続用ユーザー名 | `shlink` |
| `OCI_SSH_PRIVATE_KEY` | SSH秘密鍵 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `GITHUB_TOKEN` | 自動生成（Container Registry用） | 自動設定 |

### Secretsの設定手順

1. GitHubリポジトリの **Settings** に移動
2. **Secrets and variables** → **Actions** を選択
3. **New repository secret** をクリック
4. Secret名と値を入力して保存

## 監視・ログ

### デプロイログ

**場所**: `/opt/shlink-ui-rails/logs/deploy.log`

**内容**:
- デプロイの開始・終了時刻
- 各ステップの実行状況
- エラー情報
- ロールバック実行記録

**例**:
```
[2024-03-16 14:30:22] [INFO] Starting deployment process...
[2024-03-16 14:30:25] [INFO] Pulling latest code...
[2024-03-16 14:30:45] [SUCCESS] Application is healthy (took 23s)
[2024-03-16 14:31:02] [SUCCESS] Deployment completed successfully!
```

### GitHub Actions ログ

- ワークフロー実行ログはGitHub Actionsページで確認可能
- 各ジョブの詳細なログが利用可能
- Step Summaryにデプロイサマリーが表示

### ヘルスチェックエンドポイント

- **URL**: https://app.kety.at/health
- **期待レスポンス**: HTTP 200 OK
- **内容**: アプリケーション状態の詳細情報

## トラブルシューティング

### よくある問題

#### 1. イメージビルドが失敗する

**原因**:
- Dockerfileの問題
- 依存関係の問題
- リソース不足

**対処法**:
```bash
# ローカルでイメージビルドをテスト
docker build -f Dockerfile.production -t test-image .

# ログを確認
# GitHub Actions → failed job → build step
```

#### 2. SSH接続が失敗する

**原因**:
- SSH鍵の問題
- ホスト接続設定の問題
- ファイアウォール設定

**対処法**:
```bash
# SSH接続をローカルでテスト
ssh -i ~/.ssh/id_ed25519 shlink@your-host

# known_hostsの確認
ssh-keyscan -H your-host
```

#### 3. ヘルスチェックが失敗する

**原因**:
- アプリケーションの起動失敗
- データベース接続エラー
- 環境変数の問題

**対処法**:
```bash
# サーバーでローカルヘルスチェック
curl -f http://localhost:3000/health

# コンテナログを確認
docker-compose -f docker-compose.prod.yml logs app

# 手動ロールバック
./scripts/rollback.sh -l
./scripts/rollback.sh backup-YYYYMMDD-HHMMSS
```

#### 4. データベースマイグレーションが失敗する

**原因**:
- マイグレーション構文エラー
- データベース接続問題
- 権限不足

**対処法**:
```bash
# マイグレーション状態確認
docker-compose -f docker-compose.prod.yml run --rm app rails db:migrate:status

# 手動マイグレーション実行
docker-compose -f docker-compose.prod.yml run --rm app rails db:migrate

# ロールバック
docker-compose -f docker-compose.prod.yml run --rm app rails db:rollback
```

### 緊急時の対処

#### 即座にロールバックが必要な場合

```bash
# サーバーにSSH接続
ssh shlink@your-host

# ロールバックスクリプト実行
cd /opt/shlink-ui-rails
./scripts/rollback.sh

# または最新バックアップを確認して手動実行
./scripts/rollback.sh -l
./scripts/rollback.sh backup-YYYYMMDD-HHMMSS
```

#### サービスが完全に停止している場合

```bash
# Docker Composeで強制的に再起動
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# 最後に成功したイメージを確認
docker images | grep shlink-ui-rails

# 必要に応じて特定のイメージで起動
docker tag shlink-ui-rails:backup-YYYYMMDD-HHMMSS shlink-ui-rails:latest
docker-compose -f docker-compose.prod.yml up -d
```

## セキュリティ考慮事項

### SSH接続のセキュリティ

- SSH鍵はGitHub Secretsで安全に管理
- 接続は専用ユーザー（shlink）で実行
- known_hostsによるホスト検証

### コンテナイメージのセキュリティ

- GitHub Container Registryを使用
- プライベートリポジトリでイメージを管理
- 認証トークンによるアクセス制御

### ログのセキュリティ

- 機密情報をログに出力しない
- ログファイルの適切な権限設定
- ログローテーションによる容量管理

## パフォーマンス最適化

### ビルド時間の短縮

- Docker Buildxキャッシュの活用
- マルチステージビルドの最適化
- 依存関係の効率的なインストール

### デプロイ時間の短縮

- ゼロダウンタイムデプロイメント
- ヘルスチェック間隔の最適化
- 並列処理の活用

### リソース使用量の最適化

- 不要なDockerイメージのクリーンアップ
- ログファイルのローテーション
- バックアップの保持期間管理

## 今後の改善案

### 監視・アラート機能

- Slack/Discord通知の実装
- Prometheusメトリクスの収集
- アプリケーション性能監視（APM）の導入

### テスト強化

- E2Eテストの自動化
- パフォーマンステストの追加
- セキュリティスキャンの統合

### デプロイ戦略の改善

- Blue-Greenデプロイメントの実装
- カナリアデプロイメントの検討
- A/Bテスト機能の追加

---

このCDシステムにより、安全で効率的な本番デプロイが実現されています。問題が発生した場合は、このドキュメントのトラブルシューティングセクションを参考に対処してください。