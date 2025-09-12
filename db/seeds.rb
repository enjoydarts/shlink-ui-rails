# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# システム設定のデフォルト値を初期化
puts "初期化中: システム設定のデフォルト値..."
SystemSetting.initialize_defaults!
puts "完了: システム設定の初期化"

# 開発環境では管理者ユーザーを作成
if Rails.env.development?
  puts "初期化中: 開発環境用管理者ユーザー..."
  admin_user = User.find_or_create_by!(email: 'admin@example.com') do |user|
    user.name = '管理者'
    user.password = 'password'
    user.password_confirmation = 'password'
    user.role = 'admin'
    user.skip_confirmation!
  end
  puts "完了: 管理者ユーザー (#{admin_user.email}) を作成しました"
end
