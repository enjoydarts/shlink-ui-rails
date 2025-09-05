require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'バリデーション' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }
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
end
