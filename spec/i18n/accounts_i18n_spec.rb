require 'rails_helper'

RSpec.describe 'Accounts I18n', type: :feature do
  describe 'アカウント設定関連の国際化' do
    it 'タブラベルの翻訳が正しく定義されている' do
      expect(I18n.t('accounts.tabs.basic')).to eq('基本設定')
      expect(I18n.t('accounts.tabs.security')).to eq('セキュリティ')
      expect(I18n.t('accounts.tabs.danger')).to eq('危険な操作')
    end

    it 'タブ説明の翻訳が正しく定義されている' do
      expect(I18n.t('accounts.tabs.basic_description')).to eq('プロフィール情報の変更')
      expect(I18n.t('accounts.tabs.security_description')).to eq('パスワードとメールアドレスの管理')
      expect(I18n.t('accounts.tabs.danger_description')).to eq('アカウントの削除とロック管理')
    end

    it 'アカウント設定画面のタイトル関連翻訳が正しく定義されている' do
      expect(I18n.t('accounts.show.title')).to eq('アカウント設定')
      expect(I18n.t('accounts.show.subtitle')).to eq('プロフィール情報とセキュリティ設定を管理')
      expect(I18n.t('accounts.show.profile_settings')).to eq('プロフィール設定')
      expect(I18n.t('accounts.show.password_settings')).to eq('パスワード変更')
      expect(I18n.t('accounts.show.password_setup')).to eq('パスワード設定')
      expect(I18n.t('accounts.show.email_settings')).to eq('メールアドレス変更')
      expect(I18n.t('accounts.show.danger_zone')).to eq('危険な操作')
    end

    it 'ダンジャーゾーン関連の翻訳が正しく定義されている' do
      expect(I18n.t('accounts.danger_zone.delete_account_title')).to eq('アカウントの削除')
      expect(I18n.t('accounts.danger_zone.delete_warning_title')).to eq('削除に関する注意事項')
      expect(I18n.t('accounts.danger_zone.delete_button')).to eq('アカウントを削除する')
      expect(I18n.t('accounts.danger_zone.account_locked_message')).to eq('アカウントがロックされています')
      expect(I18n.t('accounts.danger_zone.account_not_locked')).to eq('アカウントは正常です')
      expect(I18n.t('accounts.danger_zone.unlock_account')).to eq('ロック解除メールを再送信')
    end

    it '削除警告項目の翻訳が正しく定義されている' do
      expect(I18n.t('accounts.danger_zone.delete_warning_items.data_loss')).to eq('アカウントを削除すると、すべてのデータが永久に失われます')
      expect(I18n.t('accounts.danger_zone.delete_warning_items.url_deletion')).to eq('作成した短縮URLもすべて削除されます')
      expect(I18n.t('accounts.danger_zone.delete_warning_items.irreversible')).to eq('この操作は取り消すことができません')
      expect(I18n.t('accounts.danger_zone.delete_warning_items.reregistration')).to eq('削除後は同じメールアドレスで再登録が可能です')
    end

    it 'パスワード関連の翻訳が正しく定義されている' do
      expect(I18n.t('accounts.danger_zone.current_password_delete')).to eq('現在のパスワード（削除確認用）')
      expect(I18n.t('accounts.danger_zone.current_password_delete_placeholder')).to eq('現在のパスワードを入力')
      expect(I18n.t('accounts.danger_zone.current_password_delete_help')).to eq('削除を確認するため現在のパスワードが必要です')
    end

    it 'OAuth関連の翻訳が正しく定義されている' do
      expect(I18n.t('accounts.danger_zone.oauth_delete_confirmation')).to eq('確認文字列（削除確認用）')
      expect(I18n.t('accounts.danger_zone.oauth_delete_placeholder')).to eq('「削除」と入力してください')
      expect(I18n.t('accounts.danger_zone.oauth_delete_help')).to eq('Google認証ユーザーのため、「削除」と入力して確認してください')
    end

    it 'フォーム関連の翻訳が正しく定義されている' do
      expect(I18n.t('accounts.profile_form.display_name')).to eq('表示名')
      expect(I18n.t('accounts.profile_form.display_name_placeholder')).to eq('山田 太郎')
      expect(I18n.t('accounts.profile_form.current_password')).to eq('現在のパスワード（確認用）')
      expect(I18n.t('accounts.profile_form.update_profile')).to eq('プロフィールを更新')
    end

    it 'パスワードフォーム関連の翻訳が正しく定義されている' do
      expect(I18n.t('accounts.password_form.new_password')).to eq('新しいパスワード')
      expect(I18n.t('accounts.password_form.password_confirmation')).to eq('新しいパスワード（確認）')
      expect(I18n.t('accounts.password_form.setup_password')).to eq('パスワードを設定')
      expect(I18n.t('accounts.password_form.update_password')).to eq('パスワードを変更')
    end

    it 'メールフォーム関連の翻訳が正しく定義されている' do
      expect(I18n.t('accounts.email_form.current_email')).to eq('現在のメールアドレス')
      expect(I18n.t('accounts.email_form.new_email')).to eq('新しいメールアドレス')
      expect(I18n.t('accounts.email_form.update_email')).to eq('メールアドレスを変更')
    end

    it 'メッセージ関連の翻訳が正しく定義されている' do
      expect(I18n.t('accounts.messages.profile_updated')).to eq('プロフィールが正常に更新されました。')
      expect(I18n.t('accounts.messages.password_updated')).to eq('パスワードが正常に変更されました。')
      expect(I18n.t('accounts.messages.email_update_sent')).to eq('新しいメールアドレスの確認メールを送信しました。メールをご確認ください。')
      expect(I18n.t('accounts.messages.account_deleted')).to eq('アカウントが正常に削除されました。ご利用ありがとうございました。')
      expect(I18n.t('accounts.messages.delete_confirmation_failed')).to eq('削除を確認するため「削除」と正確に入力してください。')
      expect(I18n.t('accounts.messages.current_password_invalid')).to eq('現在のパスワードが正しくありません。')
    end

    it 'ロック関連の翻訳が正しく定義されている' do
      expect(I18n.t('accounts.danger_zone.failed_attempts')).to eq('失敗回数')
      expect(I18n.t('accounts.danger_zone.locked_at')).to eq('ロック日時')
    end

    context '翻訳キーの存在確認' do
      let(:required_keys) do
        %w[
          accounts.tabs.basic
          accounts.tabs.security
          accounts.tabs.danger
          accounts.tabs.basic_description
          accounts.tabs.security_description
          accounts.tabs.danger_description
          accounts.show.title
          accounts.show.subtitle
          accounts.show.profile_settings
          accounts.show.password_settings
          accounts.show.password_setup
          accounts.show.email_settings
          accounts.show.danger_zone
          accounts.danger_zone.delete_account_title
          accounts.danger_zone.delete_warning_title
          accounts.danger_zone.delete_button
          accounts.danger_zone.delete_warning_items.data_loss
          accounts.danger_zone.delete_warning_items.url_deletion
          accounts.danger_zone.delete_warning_items.irreversible
          accounts.danger_zone.delete_warning_items.reregistration
        ]
      end

      it '必要な翻訳キーがすべて存在する' do
        required_keys.each do |key|
          expect(I18n.exists?(key, :ja)).to be_truthy, "Translation key '#{key}' is missing"
        end
      end

      it '翻訳値が空でない' do
        required_keys.each do |key|
          translation = I18n.t(key)
          expect(translation).not_to be_blank, "Translation for '#{key}' is blank"
          expect(translation).not_to include('translation missing'), "Translation for '#{key}' is missing"
        end
      end
    end
  end
end
