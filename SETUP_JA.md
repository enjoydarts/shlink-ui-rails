# 🚀 Shlink-UI-Rails 初回セットアップガイド

このガイドでは、Shlink-UI-Railsを初めてデプロイする方向けに、必要な設定を順を追って説明します。

## 📋 セットアップの流れ

### 1. 基本セットアップ
```bash
# データベースのセットアップと初期データ作成
rails db:setup
```

### 2. 管理者アカウントでログイン
- 📧 **メールアドレス**: `admin@yourdomain.com`
- 🔑 **パスワード**: `change_me_please`

⚠️ **セキュリティのため、ログイン後すぐにパスワードを変更してください**

### 3. システム設定の変更

管理者パネル > システム設定 で以下の項目を設定してください：

#### 🏠 基本システム設定
- **サイト名**: あなたのサービス名（例: "MyShortURL"）
- **サイトURL**: あなたのドメイン（例: "https://short.example.com"）
- **管理者メール**: あなたのメールアドレス
- **サービス説明**: SEO用の説明文

#### 📧 メール設定（必須）
パスワードリセットなどのメール送信に必要です。

**Gmail を使用する場合：**
1. **メール送信方法**: `smtp`
2. **送信者アドレス**: `noreply@yourdomain.com`
3. **SMTPサーバー**: `smtp.gmail.com`
4. **SMTPポート**: `587`
5. **SMTPユーザー名**: あなたのGmailアドレス
6. **SMTPパスワード**: [Gmailアプリパスワード](https://support.google.com/accounts/answer/185833)を取得して設定

**MailerSend を使用する場合：**
1. **メール送信方法**: `mailersend`
2. **MailerSend APIキー**: [MailerSend](https://www.mailersend.com)から取得

#### 🛡️ CAPTCHA設定（本番環境推奨）
スパムや悪用から保護するため、本番環境では有効にしてください。

1. [Cloudflare Turnstile](https://dash.cloudflare.com/profile/api-tokens)（無料）でアカウント作成
2. Site KeyとSecret Keyを取得
3. **CAPTCHA機能**: `有効`
4. キーを設定

## 🔧 環境変数での設定（オプション）

システム設定の一部は環境変数でも設定できます：

```bash
# 管理者アカウント
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=your_secure_password

# データベース
DATABASE_URL=mysql2://user:password@host:3306/database

# 本番環境用
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key_base
```

## 📝 本番環境での追加設定

### SSL/TLS設定
```bash
# Let's Encrypt等でSSL証明書を取得
# サイトURLを https:// に変更
```

### セキュリティ設定
- **強固なパスワード要求**: `有効`
- **ログイン試行制限**: `5回`
- **セッション有効期限**: `24時間`

### パフォーマンス設定
- **キャッシュ有効期限**: `3600秒`（1時間）
- **統計データ更新間隔**: `15分`
- **一覧表示件数**: `20件`

## 🆘 トラブルシューティング

### メール送信ができない
1. SMTP設定を「テスト」ボタンで確認
2. ファイアウォールでポート587が開いているか確認
3. Gmailの場合、アプリパスワードを使用しているか確認

### CAPTCHA が表示されない
1. Site Keyが正しく設定されているか確認
2. ドメインがCloudflare Turnstileに登録されているか確認

### 管理者パスワードを忘れた場合
```bash
# Railsコンソールでパスワード変更
rails console
admin = User.find_by(email: 'admin@yourdomain.com')
admin.update!(password: 'new_password', password_confirmation: 'new_password')
```

## 🎉 セットアップ完了

設定が完了したら、以下をテストしてください：

- [ ] ユーザー登録・ログインが動作する
- [ ] 短縮URL作成が動作する
- [ ] パスワードリセットメールが届く
- [ ] CAPTCHA が表示される（有効にした場合）

問題がある場合は、システム設定の「テスト」ボタンで各機能をテストできます。

---

**🔗 その他のドキュメント**
- [README.md](README.md) - 開発環境セットアップ（英語）
- [README_ja.md](README_ja.md) - 日本語ドキュメント
- [SETUP_EN.md](SETUP_EN.md) - 英語版セットアップガイド
- API Documentation - API使用方法
- Troubleshooting - 詳細なトラブルシューティング