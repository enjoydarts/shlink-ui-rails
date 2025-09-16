#!/bin/bash

# 本番環境用ディレクトリ作成スクリプト
# docker-compose.prod.yml実行前に実行してください

echo "Setting up production directories..."

# ログディレクトリ作成
mkdir -p logs
echo "Created logs directory"

# ストレージディレクトリ作成
mkdir -p storage
echo "Created storage directory"

# 権限設定（可能な場合のみ）
echo "Setting directory permissions..."

# chmod（可能な場合のみ実行）
if chmod 755 logs storage 2>/dev/null; then
    echo "✓ Directory permissions set to 755"
else
    echo "⚠ Could not set directory permissions (chmod failed)"
    echo "  This is normal on some systems. Docker will handle permissions."
fi

# 所有権変更（sudoが使える場合のみ）
if command -v sudo &> /dev/null && sudo -n true 2>/dev/null; then
    if sudo chown -R 110:111 logs storage 2>/dev/null; then
        echo "✓ Directory ownership set to 110:111 (shlink user)"
    else
        echo "⚠ Could not change directory ownership"
        echo "  You may need to run: sudo chown -R 110:111 logs storage"
    fi
else
    echo "⚠ Cannot use sudo or no sudo access"
    echo "  If you have permission issues, try:"
    echo "  sudo chown -R 110:111 logs storage"
    echo "  Or run docker-compose and fix permissions inside container:"
    echo "  docker-compose -f docker-compose.prod.yml exec app chown -R app:app /app/log /app/storage"
fi

echo ""
echo "🎉 Production directories setup complete!"
echo "📁 Created: ./logs (for application logs)"
echo "📁 Created: ./storage (for file uploads)"
echo ""
echo "🚀 You can now run: docker-compose -f docker-compose.prod.yml up -d"
