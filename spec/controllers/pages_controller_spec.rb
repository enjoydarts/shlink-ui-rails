# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagesController, type: :request do
  describe 'GET #home' do
    context 'ログインしていない場合' do
      it 'homeテンプレートを表示すること' do
        get root_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'ログインしている場合' do
      let(:user) { create(:user) }

      before do
        sign_in user, scope: :user
      end

      it 'ダッシュボードにリダイレクトすること' do
        get root_path
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
