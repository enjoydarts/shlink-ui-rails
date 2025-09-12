# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TotpService, type: :service do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user: user) }

  describe 'バリデーション' do
    it 'userが必要であること' do
      service_without_user = described_class.new
      expect(service_without_user).not_to be_valid
      expect(service_without_user.errors[:user]).to be_present
    end

    it 'userがあれば有効であること' do
      expect(service).to be_valid
    end
  end

  describe '.generate_secret_for' do
    it 'ユーザー用の秘密鍵を生成すること' do
      allow_any_instance_of(described_class).to receive(:generate_secret).and_return('TESTSECRET123456')
      expect(described_class.generate_secret_for(user)).to eq('TESTSECRET123456')
    end
  end

  describe '.generate_qr_code' do
    before do
      user.otp_secret_key = 'encrypted_secret'
    end

    it 'QRコードを生成すること' do
      allow_any_instance_of(described_class).to receive(:generate_qr_code).and_return('<svg>qr_code</svg>')
      expect(described_class.generate_qr_code(user)).to eq('<svg>qr_code</svg>')
    end
  end

  describe '.verify_code' do
    it 'TOTPコードを検証すること' do
      allow_any_instance_of(described_class).to receive(:verify_code).with('123456', drift: 30).and_return(true)
      expect(described_class.verify_code(user, '123456')).to be true
    end
  end

  describe '.verify_backup_code' do
    it 'バックアップコードを検証すること' do
      allow_any_instance_of(described_class).to receive(:verify_backup_code).with('backup123').and_return(true)
      expect(described_class.verify_backup_code(user, 'backup123')).to be true
    end
  end

  describe '.enable_for' do
    it '2FAを有効化すること' do
      allow_any_instance_of(described_class).to receive(:enable_two_factor).with('123456').and_return(true)
      expect(described_class.enable_for(user, '123456')).to be true
    end
  end

  describe '.disable_for' do
    it '2FAを無効化すること' do
      allow_any_instance_of(described_class).to receive(:disable_two_factor).and_return(true)
      expect(described_class.disable_for(user)).to be true
    end
  end

  describe '#generate_secret' do
    it 'Base32のランダム秘密鍵を生成して保存すること' do
      allow(ROTP::Base32).to receive(:random).and_return('TESTSECRET123456')
      allow(service).to receive(:encrypt_secret).with('TESTSECRET123456').and_return('encrypted_secret')

      expect(user).to receive(:save!)
      secret = service.generate_secret

      expect(secret).to eq('TESTSECRET123456')
      expect(user.otp_secret_key).to eq('encrypted_secret')
    end
  end

  describe '#verify_code' do
    let(:mock_totp) { instance_double('ROTP::TOTP') }

    before do
      user.otp_secret_key = 'encrypted_secret'
      allow(service).to receive(:decrypt_secret).with('encrypted_secret').and_return('TESTSECRET123456')
      allow(ROTP::TOTP).to receive(:new).with('TESTSECRET123456').and_return(mock_totp)
    end

    context '有効なコードの場合' do
      it 'trueを返すこと' do
        allow(mock_totp).to receive(:verify).with('123456', drift_behind: 30, drift_ahead: 30).and_return(Time.current.to_i)
        expect(service.verify_code('123456')).to be true
      end
    end

    context '無効なコードの場合' do
      it 'falseを返すこと' do
        allow(mock_totp).to receive(:verify).with('invalid', drift_behind: 30, drift_ahead: 30).and_return(nil)
        expect(service.verify_code('invalid')).to be false
      end
    end

    context '空のコードの場合' do
      it 'falseを返すこと' do
        expect(service.verify_code('')).to be false
        expect(service.verify_code(nil)).to be false
      end
    end
  end

  describe '#generate_backup_codes' do
    it 'バックアップコードを生成すること' do
      allow(service).to receive(:generate_backup_code).and_return('backup01', 'backup02', 'backup03', 'backup04', 'backup05', 'backup06', 'backup07', 'backup08')
      allow(service).to receive(:encrypt_backup_codes).with([ 'backup01', 'backup02', 'backup03', 'backup04', 'backup05', 'backup06', 'backup07', 'backup08' ]).and_return('encrypted_codes')

      codes = service.generate_backup_codes

      expect(codes.length).to eq(8)
      expect(codes).to include('backup01', 'backup02')
      expect(user.otp_backup_codes).to eq('encrypted_codes')
      expect(user.otp_backup_codes_generated_at).to be_within(1.second).of(Time.current)
    end
  end

  describe '#verify_backup_code' do
    before do
      user.otp_backup_codes = 'encrypted_codes'
      allow(service).to receive(:decrypt_backup_codes).with('encrypted_codes').and_return([ 'backup01', 'backup02', 'used123' ])
    end

    context '有効なバックアップコードの場合' do
      it 'コードを使用して削除し、trueを返すこと' do
        # 使用後のコードリストをモック
        allow(service).to receive(:encrypt_backup_codes).with([ 'backup02', 'used123' ]).and_return('updated_encrypted_codes')
        expect(user).to receive(:save!)

        result = service.verify_backup_code('backup01')

        expect(result).to be true
        expect(user.otp_backup_codes).to eq('updated_encrypted_codes')
      end
    end

    context '無効なバックアップコードの場合' do
      it 'falseを返すこと' do
        result = service.verify_backup_code('invalid')
        expect(result).to be false
      end
    end
  end

  describe '#enable_two_factor' do
    before do
      allow(service).to receive(:verify_code).with('123456').and_return(true)
      allow(service).to receive(:generate_backup_codes).and_return([ 'backup01', 'backup02' ])
    end

    context '有効な検証コードの場合' do
      it '2FAを有効化してtrueを返すこと' do
        expect(user).to receive(:save!)

        result = service.enable_two_factor('123456')

        expect(result).to be true
        expect(user.otp_required_for_login).to be true
      end
    end

    context '無効な検証コードの場合' do
      before do
        allow(service).to receive(:verify_code).with('invalid').and_return(false)
      end

      it 'falseを返すこと' do
        result = service.enable_two_factor('invalid')
        expect(result).to be false
      end
    end
  end

  describe '#disable_two_factor' do
    before do
      user.otp_required_for_login = true
      user.otp_secret_key = 'encrypted_secret'
      user.otp_backup_codes = 'encrypted_codes'
      user.otp_backup_codes_generated_at = Time.current
    end

    it '2FA設定をクリアすること' do
      expect(user).to receive(:save!).and_return(true)

      result = service.disable_two_factor

      expect(user.otp_required_for_login).to be false
      expect(user.otp_secret_key).to be_nil
      expect(user.otp_backup_codes).to be_nil
      expect(user.otp_backup_codes_generated_at).to be_nil
    end
  end

  describe '#get_secret' do
    context '既存の秘密鍵がある場合' do
      before do
        user.otp_secret_key = 'encrypted_secret'
        allow(service).to receive(:decrypt_secret).with('encrypted_secret').and_return('EXISTINGSECRET')
      end

      it '既存の秘密鍵を返すこと' do
        expect(service.get_secret).to eq('EXISTINGSECRET')
      end
    end

    context '秘密鍵がない場合' do
      before do
        user.otp_secret_key = nil
        allow(service).to receive(:generate_secret).and_return('NEWSECRET')
      end

      it '新しい秘密鍵を生成して返すこと' do
        expect(service.get_secret).to eq('NEWSECRET')
      end
    end
  end
end
