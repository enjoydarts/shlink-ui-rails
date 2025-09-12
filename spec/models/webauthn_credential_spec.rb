# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebauthnCredential, type: :model do
  let(:user) { create(:user) }
  let(:credential) { create(:webauthn_credential, user: user) }

  describe 'アソシエーション' do
    it { should belong_to(:user) }
  end

  describe 'バリデーション' do
    it 'external_idが必要であること' do
      credential = build(:webauthn_credential, user: user, external_id: nil)
      expect(credential).not_to be_valid
      expect(credential.errors[:external_id]).to include('を入力してください')
    end

    it 'public_keyが必要であること' do
      credential = build(:webauthn_credential, user: user, public_key: nil)
      expect(credential).not_to be_valid
      expect(credential.errors[:public_key]).to include('を入力してください')
    end

    it 'nicknameが必要であること' do
      credential = build(:webauthn_credential, user: user, nickname: nil)
      expect(credential).not_to be_valid
      expect(credential.errors[:nickname]).to include('を入力してください')
    end

    it 'sign_countが数値であること' do
      credential = build(:webauthn_credential, user: user, sign_count: -1)
      expect(credential).not_to be_valid
      expect(credential.errors[:sign_count]).to include('は0以上の値にしてください')
    end
  end

  describe 'デフォルト値' do
    it 'sign_countが0であること' do
      new_credential = WebauthnCredential.new(user: user, external_id: 'test', public_key: 'test', nickname: 'test')
      expect(new_credential.sign_count).to eq(0)
    end

    it 'activeがtrueであること' do
      new_credential = WebauthnCredential.new(user: user, external_id: 'test', public_key: 'test', nickname: 'test')
      expect(new_credential.active).to be true
    end
  end

  describe 'スコープ' do
    describe '.active' do
      it 'アクティブなクレデンシャルのみを返すこと' do
        active_credential = create(:webauthn_credential, user: user, active: true)
        inactive_credential = create(:webauthn_credential, user: user, active: false)

        expect(WebauthnCredential.active).to include(active_credential)
        expect(WebauthnCredential.active).not_to include(inactive_credential)
      end
    end
  end

  describe '#display_info' do
    it 'クレデンシャル情報を含むハッシュを返すこと' do
      result = credential.display_info

      expect(result).to include(
        :id,
        :nickname,
        :created
      )
      expect(result[:id]).to eq(credential.id)
      expect(result[:nickname]).to eq(credential.nickname)
    end

    context 'last_used_atが設定されている場合' do
      before { credential.touch_last_used! }

      it 'last_usedが含まれること' do
        result = credential.display_info
        expect(result).to include(:last_used)
      end
    end
  end

  describe '#touch_last_used!' do
    it '最終使用日時を更新すること' do
      expect { credential.touch_last_used! }.to change { credential.last_used_at }
    end
  end

  describe '#update_sign_count!' do
    it 'サインカウントを更新すること' do
      new_count = 5
      expect { credential.update_sign_count!(new_count) }.to change { credential.sign_count }.to(new_count)
    end
  end


  describe '#deactivate!' do
    it 'クレデンシャルを無効化すること' do
      expect { credential.deactivate! }.to change { credential.active }.from(true).to(false)
    end
  end

  describe '#security_level' do
    context 'sign_countが0で最近使用されていない場合' do
      it '"low"を返すこと' do
        expect(credential.security_level).to eq('low')
      end
    end

    context 'sign_countがあるが最近使用されていない場合' do
      before { credential.update!(sign_count: 5) }

      it '"medium"を返すこと' do
        expect(credential.security_level).to eq('medium')
      end
    end

    context 'sign_countがあり最近使用されている場合' do
      before do
        credential.update!(sign_count: 5)
        credential.touch_last_used!
      end

      it '"high"を返すこと' do
        expect(credential.security_level).to eq('high')
      end
    end
  end

  describe '#security_level_color' do
    it 'セキュリティレベルに応じた色クラスを返すこと' do
      allow(credential).to receive(:security_level).and_return('high')
      expect(credential.security_level_color).to eq('text-green-600 bg-green-100')

      allow(credential).to receive(:security_level).and_return('medium')
      expect(credential.security_level_color).to eq('text-yellow-600 bg-yellow-100')

      allow(credential).to receive(:security_level).and_return('low')
      expect(credential.security_level_color).to eq('text-gray-600 bg-gray-100')
    end
  end

  describe '#security_level_label' do
    it 'セキュリティレベルに応じたラベルを返すこと' do
      allow(credential).to receive(:security_level).and_return('high')
      expect(credential.security_level_label).to eq('高')

      allow(credential).to receive(:security_level).and_return('medium')
      expect(credential.security_level_label).to eq('中')

      allow(credential).to receive(:security_level).and_return('low')
      expect(credential.security_level_label).to eq('低')
    end
  end
end
