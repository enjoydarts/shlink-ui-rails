require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'バリデーション' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(8) }
    it 'roleの値が適切に設定されること' do
      user = build(:user, role: 'normal_user')
      expect(user.role).to eq('normal_user')

      user = build(:user, role: 'admin')
      expect(user.role).to eq('admin')
    end

    context 'OAuthユーザーの場合' do
      subject { build(:user, :from_oauth) }

      it { should validate_presence_of(:name) }
    end
  end

  describe 'エニューム' do
    it { should define_enum_for(:role).with_values(normal_user: 'normal_user', admin: 'admin').backed_by_column_of_type(:string) }
  end

  describe 'デフォルト値' do
    let(:user) { User.new(email: 'test@example.com', password: 'password') }

    it 'デフォルトロールはnormal_userであること' do
      expect(user.role).to eq('normal_user')
    end
  end

  describe '.from_omniauth' do
    let(:auth) do
      double(
        provider: 'google_oauth2',
        uid: '123456789',
        info: double(
          email: 'test@example.com',
          name: 'Test User'
        )
      )
    end

    context '新規ユーザーの場合' do
      it 'ユーザーが作成されること' do
        expect {
          User.from_omniauth(auth)
        }.to change(User, :count).by(1)
      end

      it '適切な属性が設定されること' do
        user = User.from_omniauth(auth)
        expect(user.email).to eq('test@example.com')
        expect(user.name).to eq('Test User')
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456789')
        expect(user.password).to be_present
      end
    end

    context '既存ユーザーの場合' do
      before do
        create(:user, email: 'test@example.com')
      end

      it 'ユーザーが作成されないこと' do
        expect {
          User.from_omniauth(auth)
        }.not_to change(User, :count)
      end

      it '既存ユーザーが返されること' do
        existing_user = User.find_by(email: 'test@example.com')
        returned_user = User.from_omniauth(auth)
        expect(returned_user.id).to eq(existing_user.id)
      end
    end
  end

  describe '#from_omniauth?' do
    it 'OAuthユーザーの場合はtrueを返すこと' do
      user = build(:user, :from_oauth)
      expect(user).to be_from_omniauth
    end

    it '通常ユーザーの場合はfalseを返すこと' do
      user = build(:user)
      expect(user).not_to be_from_omniauth
    end
  end

  describe '#display_name' do
    context '名前がある場合' do
      let(:user) { build(:user, name: 'Test User') }

      it '名前を返すこと' do
        expect(user.display_name).to eq('Test User')
      end
    end

    context '名前がない場合' do
      let(:user) { build(:user, email: 'test@example.com', name: nil) }

      it 'メールアドレスのローカル部を返すこと' do
        expect(user.display_name).to eq('test')
      end
    end
  end

  describe 'アソシエーション' do
    it { should have_many(:short_urls).dependent(:destroy) }
  end

  describe '#recent_short_urls' do
    let(:user) { create(:user) }
    let!(:old_url) { create(:short_url, user: user, date_created: 2.days.ago) }
    let!(:new_url) { create(:short_url, user: user, date_created: 1.day.ago) }
    let!(:newest_url) { create(:short_url, user: user, date_created: Time.current) }
    let!(:other_user_url) { create(:short_url) }

    context 'limitを指定しない場合' do
      it 'ユーザーの全短縮URLを作成日時の降順で返すこと' do
        expect(user.recent_short_urls).to eq([ newest_url, new_url, old_url ])
        expect(user.recent_short_urls).not_to include(other_user_url)
      end
    end

    context 'limitを指定した場合' do
      it '指定した件数の短縮URLを返すこと' do
        expect(user.recent_short_urls(2)).to eq([ newest_url, new_url ])
        expect(user.recent_short_urls(2).count).to eq(2)
      end
    end
  end

  describe '二段階認証（2FA）' do
    let(:user) { create(:user) }
    let(:oauth_user) { create(:user, :from_oauth, provider: 'google_oauth2') }

    describe '#two_factor_enabled?' do
      context 'TOTPもWebAuthnも無効の場合' do
        it 'falseを返すこと' do
          expect(user.two_factor_enabled?).to be false
        end
      end

      context 'TOTPが有効の場合' do
        before do
          user.otp_required_for_login = true
          user.otp_secret_key = 'test_secret'
        end

        it 'trueを返すこと' do
          expect(user.two_factor_enabled?).to be true
        end
      end

      context 'WebAuthnが有効の場合' do
        before do
          allow(user).to receive(:webauthn_enabled?).and_return(true)
        end

        it 'trueを返すこと' do
          expect(user.two_factor_enabled?).to be true
        end
      end

      context 'TOTPとWebAuthn両方が有効の場合' do
        before do
          user.otp_required_for_login = true
          user.otp_secret_key = 'test_secret'
          allow(user).to receive(:webauthn_enabled?).and_return(true)
        end

        it 'trueを返すこと' do
          expect(user.two_factor_enabled?).to be true
        end
      end
    end

    describe '#totp_enabled?' do
      context 'otp_required_for_loginがfalseの場合' do
        before { user.otp_required_for_login = false }

        it 'falseを返すこと' do
          expect(user.totp_enabled?).to be false
        end
      end

      context 'otp_secret_keyがない場合' do
        before do
          user.otp_required_for_login = true
          user.otp_secret_key = nil
        end

        it 'falseを返すこと' do
          expect(user.totp_enabled?).to be false
        end
      end

      context 'otp_required_for_loginがtrueでotp_secret_keyがある場合' do
        before do
          user.otp_required_for_login = true
          user.otp_secret_key = 'test_secret'
        end

        it 'trueを返すこと' do
          expect(user.totp_enabled?).to be true
        end
      end
    end

    describe '#webauthn_enabled?' do
      context 'WebAuthnクレデンシャルがない場合' do
        it 'falseを返すこと' do
          expect(user.webauthn_enabled?).to be false
        end
      end

      context 'WebAuthnクレデンシャルがある場合' do
        before do
          # アクティブなWebAuthnCredentialが存在することを想定
          allow(user.webauthn_credentials).to receive(:active).and_return(double(exists?: true))
        end

        it 'trueを返すこと' do
          expect(user.webauthn_enabled?).to be true
        end
      end
    end

    describe '#requires_two_factor?' do
      context '2FAが無効の場合' do
        it 'falseを返すこと' do
          expect(user.requires_two_factor?).to be false
        end
      end

      context '2FAが有効で通常ユーザーの場合' do
        before do
          user.otp_required_for_login = true
          user.otp_secret_key = 'test_secret'
        end

        it 'trueを返すこと' do
          expect(user.requires_two_factor?).to be true
        end
      end

      context '2FAが有効でGoogle OAuthユーザーの場合' do
        before do
          oauth_user.otp_required_for_login = true
          oauth_user.otp_secret_key = 'test_secret'
        end

        it 'falseを返すこと（OAuth認証は2FAをスキップ）' do
          expect(oauth_user.requires_two_factor?).to be false
        end
      end
    end

    describe '#skip_two_factor_for_oauth?' do
      context '通常ユーザーの場合' do
        it 'falseを返すこと' do
          expect(user.skip_two_factor_for_oauth?).to be false
        end
      end

      context 'Google OAuthユーザーの場合' do
        it 'trueを返すこと' do
          expect(oauth_user.skip_two_factor_for_oauth?).to be true
        end
      end

      context 'OAuth以外のプロバイダーの場合' do
        let(:other_oauth_user) { create(:user, :from_oauth, provider: 'github') }

        it 'falseを返すこと' do
          expect(other_oauth_user.skip_two_factor_for_oauth?).to be false
        end
      end
    end

    describe '#verify_two_factor_code' do
      let(:totp_service) { class_double('TotpService') }

      before do
        stub_const('TotpService', totp_service)
        user.otp_required_for_login = true
        user.otp_secret_key = 'test_secret'
      end

      context '空のコードの場合' do
        it 'falseを返すこと' do
          expect(user.verify_two_factor_code('')).to be false
          expect(user.verify_two_factor_code(nil)).to be false
        end
      end

      context '有効なTOTPコードの場合' do
        it 'TotpServiceを呼び出してtrueを返すこと' do
          allow(totp_service).to receive(:verify_code).with(user, '123456').and_return(true)
          expect(user.verify_two_factor_code('123456')).to be true
        end
      end

      context 'TOTPが無効でバックアップコードが有効の場合' do
        it 'TotpServiceを呼び出してバックアップコードを検証すること' do
          allow(totp_service).to receive(:verify_code).with(user, 'backup123').and_return(false)
          allow(totp_service).to receive(:verify_backup_code).with(user, 'backup123').and_return(true)
          expect(user.verify_two_factor_code('backup123')).to be true
        end
      end
    end

    describe '#webauthn_id' do
      context 'webauthn_user_idが既に設定されている場合' do
        before { user.webauthn_user_id = 'existing_id' }

        it '既存のIDを返すこと' do
          expect(user.webauthn_id).to eq('existing_id')
        end
      end

      context 'webauthn_user_idが未設定の場合' do
        before { user.webauthn_user_id = nil }

        it '新しいIDを生成して保存すること' do
          expect(SecureRandom).to receive(:random_bytes).with(64).and_return('new_random_id')
          expect(user).to receive(:update!).with(webauthn_user_id: 'new_random_id')
          expect(user.webauthn_id).to eq('new_random_id')
        end
      end
    end
  end
end
