# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AsyncDeviseMailer, type: :mailer do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:token) { 'test-token' }
  let(:opts) { {} }

  before do
    allow(DeviseMailerJob).to receive(:perform_later)
  end

  describe 'ConfigShortcuts統合' do
    it 'ConfigShortcutsモジュールをインクルードしていること' do
      expect(described_class.included_modules).to include(ConfigShortcuts)
    end

    it '設定ショートカットメソッドにアクセスできること' do
      mailer = described_class.new
      expect(mailer).to respond_to(:email_from_address)
      expect(mailer).to respond_to(:shlink_base_url)
    end
  end

  describe '#confirmation_instructions' do
    it 'DeviseMailerJobを非同期実行すること' do
      expect(DeviseMailerJob).to receive(:perform_later).with(:confirmation_instructions, user, token, opts)

      described_class.confirmation_instructions(user, token, opts)
    end

    it 'オプション付きで正しく呼び出すこと' do
      custom_opts = { custom: 'value' }
      expect(DeviseMailerJob).to receive(:perform_later).with(:confirmation_instructions, user, token, custom_opts)

      described_class.confirmation_instructions(user, token, custom_opts)
    end
  end

  describe '#reset_password_instructions' do
    it 'DeviseMailerJobを非同期実行すること' do
      expect(DeviseMailerJob).to receive(:perform_later).with(:reset_password_instructions, user, token, opts)

      described_class.reset_password_instructions(user, token, opts)
    end

    it 'オプション付きで正しく呼び出すこと' do
      custom_opts = { reset: 'option' }
      expect(DeviseMailerJob).to receive(:perform_later).with(:reset_password_instructions, user, token, custom_opts)

      described_class.reset_password_instructions(user, token, custom_opts)
    end
  end

  describe '#unlock_instructions' do
    it 'DeviseMailerJobを非同期実行すること' do
      expect(DeviseMailerJob).to receive(:perform_later).with(:unlock_instructions, user, token, opts)

      described_class.unlock_instructions(user, token, opts)
    end

    it 'オプション付きで正しく呼び出すこと' do
      custom_opts = { unlock: 'option' }
      expect(DeviseMailerJob).to receive(:perform_later).with(:unlock_instructions, user, token, custom_opts)

      described_class.unlock_instructions(user, token, custom_opts)
    end
  end

  describe '#email_changed' do
    it 'DeviseMailerJobを非同期実行すること（トークンなし）' do
      expect(DeviseMailerJob).to receive(:perform_later).with(:email_changed, user, nil, opts)

      described_class.email_changed(user, opts)
    end

    it 'オプション付きで正しく呼び出すこと' do
      custom_opts = { email: 'changed' }
      expect(DeviseMailerJob).to receive(:perform_later).with(:email_changed, user, nil, custom_opts)

      described_class.email_changed(user, custom_opts)
    end
  end

  describe '#password_change' do
    it 'DeviseMailerJobを非同期実行すること（トークンなし）' do
      expect(DeviseMailerJob).to receive(:perform_later).with(:password_change, user, nil, opts)

      described_class.password_change(user, opts)
    end

    it 'オプション付きで正しく呼び出すこと' do
      custom_opts = { password: 'changed' }
      expect(DeviseMailerJob).to receive(:perform_later).with(:password_change, user, nil, custom_opts)

      described_class.password_change(user, custom_opts)
    end
  end

  describe 'メーラーメソッド定義確認' do
    it 'confirmation_instructionsメソッドが定義されていること' do
      expect(described_class.instance_methods).to include(:confirmation_instructions)
    end

    it 'reset_password_instructionsメソッドが定義されていること' do
      expect(described_class.instance_methods).to include(:reset_password_instructions)
    end

    it 'unlock_instructionsメソッドが定義されていること' do
      expect(described_class.instance_methods).to include(:unlock_instructions)
    end

    it 'email_changedメソッドが定義されていること' do
      expect(described_class.instance_methods).to include(:email_changed)
    end

    it 'password_changeメソッドが定義されていること' do
      expect(described_class.instance_methods).to include(:password_change)
    end
  end
end
