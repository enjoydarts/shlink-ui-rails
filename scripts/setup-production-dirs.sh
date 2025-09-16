#!/bin/bash

# 本番環境用ディレクトリ作成スクリプト
# docker-compose.prod.yml実行前に実行してください

echo "Setting up production directories..."

# ログディレクトリ作成
mkdir -p logs
chmod 755 logs

# ストレージディレクトリ作成
mkdir -p storage
chmod 755 storage

# ユーザー1000:1000に所有権を変更（コンテナ内のユーザーに合わせる）
if command -v chown &> /dev/null; then
    sudo chown -R 1000:1000 logs storage
    echo "Directory ownership set to 1000:1000"
else
    echo "Warning: chown command not available. You may need to set directory ownership manually."
fi

echo "Production directories setup complete!"
echo "You can now run: docker-compose -f docker-compose.prod.yml up -d"