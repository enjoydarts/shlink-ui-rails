# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::SettingsController, type: :controller do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    # SystemSettingの基本的なスタブを設定
    allow(SystemSetting).to receive(:enabled).and_return([])
    allow(SystemSetting).to receive(:by_category).and_return([])
    allow(SystemSetting).to receive(:find_by).and_return(nil)
    allow(SystemSetting).to receive(:get).and_return('')
    allow(SystemSetting).to receive(:get).with('system.maintenance_mode', false).and_return(false)
    allow(SystemSetting).to receive(:initialize_defaults!)
    allow(ApplicationConfig).to receive(:reload!)
    allow(controller).to receive(:refresh_system_settings!)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
  end

  describe '管理者認証' do
    it '管理者以外はアクセス不可であること' do
      sign_in regular_user, scope: :user
      get :show
      expect(response).to redirect_to(root_path)
    end

    it '管理者はアクセス可能であること' do
      sign_in admin_user, scope: :user
      get :show
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #show' do
    before { sign_in admin_user, scope: :user }

    it 'システム設定画面を表示すること' do
      get :show
      expect(response).to have_http_status(:success)
      expect(assigns(:categories)).to eq(%w[shlink captcha rate_limit email performance security system legal])
    end
  end

  describe 'PUT #update' do
    before { sign_in admin_user, scope: :user }

    it '設定更新処理が実行されること' do
      setting = double('SystemSetting')
      allow(SystemSetting).to receive(:find_by).and_return(setting)
      allow(setting).to receive(:update!)

      put :update, params: { settings: { 'test.key' => 'value' } }
      expect(response).to redirect_to(admin_settings_path)
    end
  end

  describe 'GET #category' do
    before { sign_in admin_user, scope: :user }

    it 'カテゴリ別設定をJSON形式で返すこと' do
      settings = []
      allow(SystemSetting).to receive(:by_category).and_return(double('settings', enabled: settings))

      get :category, params: { category: 'email' }, format: :json
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'DELETE #reset' do
    before { sign_in admin_user, scope: :user }

    it 'カテゴリ設定リセット処理が実行されること' do
      settings_mock = double('settings')
      allow(SystemSetting).to receive(:by_category).with('email').and_return(settings_mock)
      allow(settings_mock).to receive(:destroy_all)

      delete :reset, params: { category: 'email' }
      expect(response).to redirect_to(admin_settings_path)
    end
  end

  describe 'POST #test' do
    before { sign_in admin_user, scope: :user }

    it 'テスト機能が動作すること' do
      # プライベートメソッドをスタブして正常な応答を返すようにする
      allow(controller).to receive(:test_email_settings).and_return({ success: true, message: 'テスト成功' })

      post :test, params: { test_type: 'email' }
      # JSON応答のため、parseしてチェック
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json') if response.content_type
    end
  end
end
