# 本番環境セットアップガイド

## 自動セットアップ（推奨）

```bash
# ディレクトリ作成と権限設定
./scripts/setup-production-dirs.sh

# サービス起動
docker-compose -f docker-compose.prod.yml up -d
```

## マニュアルセットアップ

自動スクリプトが動作しない場合は、以下の手順で手動セットアップしてください：

### 1. ディレクトリ作成

```bash
mkdir -p logs storage
```

### 2. 権限設定（権限エラーが出る場合のみ実行）

```bash
# 方法A: sudo権限がある場合
sudo chown -R 1000:1000 logs storage

# 方法B: sudo権限がない場合
# Dockerコンテナ起動後に以下を実行：
docker-compose -f docker-compose.prod.yml exec app chown -R app:app /app/log /app/storage
```

### 3. サービス起動

```bash
docker-compose -f docker-compose.prod.yml up -d
```

### 4. 動作確認

```bash
# サービス状態確認
docker-compose -f docker-compose.prod.yml ps

# ログ確認
docker-compose -f docker-compose.prod.yml logs app

# リアルタイムログ監視
tail -f logs/production.log
```

## トラブルシューティング

### パーミッションエラーが出る場合

```bash
# コンテナ内で権限修正
docker-compose -f docker-compose.prod.yml exec app bash
chown -R app:app /app/log /app/storage /app/tmp
exit
```

### ログファイルが作成されない場合

```bash
# ログディレクトリの確認
ls -la logs/

# コンテナ内でのログ確認
docker-compose -f docker-compose.prod.yml logs app
```