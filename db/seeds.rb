# ===============================================
# Shlink-UI-Rails 初期設定セットアップ
# ===============================================
#
# このファイルは初回セットアップ時に実行され、システム設定のデフォルト値と
# 管理者ユーザーを作成します。
#
# 実行方法: rails db:seed

class Seeder
  def self.run!
    puts ""
    puts "🚀 Shlink-UI-Rails セットアップを開始します..."
    puts ""

    # システム設定のデフォルト値を初期化
    puts "📋 システム設定のデフォルト値を初期化中..."
    SystemSetting.initialize_defaults!
    puts "✅ システム設定の初期化完了 (#{SystemSetting.count}個の設定項目)"

    # 管理者ユーザーを作成（全環境）
    puts ""
    puts "👤 管理者ユーザーを作成中..."

    admin_email = 'admin@yourdomain.com'
    admin_password = self.generate_password(10)

    admin_user = User.find_or_create_by!(email: admin_email) do |user|
      user.name = '管理者'
      user.password = admin_password
      user.password_confirmation = admin_password
      user.role = 'admin'
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    end

    puts "✅ 管理者ユーザー作成完了"
    puts "   📧 メール: #{admin_user.email}"
    puts "   🔑 パスワード: #{admin_password}"

    puts ""
    puts "📝 次のステップ:"
    puts "   1. 管理者でログインしてください: #{admin_user.email}"
    puts "   2. 管理者パネル > システム設定 で以下を設定してください:"
    puts "      • サイト名・URL・管理者メール"
    puts "      • メール送信設定（SMTP または MailerSend）"
    puts "      • CAPTCHA設定（本番環境推奨）"
    puts "   3. 管理者パスワードを変更してください"
    puts ""
    puts "🎉 セットアップ完了！"
    puts ""
  end

  private

  def self.generate_password(length = 10)
    # 各カテゴリの文字セット
    uppercase = ('A'..'Z').to_a
    lowercase = ('a'..'z').to_a
    digits    = ('0'..'9').to_a
    symbols   = %w[! @ # $ % ^ & * ( ) - _ = + [ ] { } ; : , . ?]

    # まずは必ず1文字ずつ確保
    result = []
    result << uppercase.sample
    result << lowercase.sample
    result << digits.sample
    result << symbols.sample

    # 残りは全カテゴリからランダムに選ぶ
    all_chars = uppercase + lowercase + digits + symbols
    (length - result.size).times { result << all_chars.sample }

    # シャッフルして返す
    result.shuffle.join
  end
end

Seeder.run!
