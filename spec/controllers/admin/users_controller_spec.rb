require 'rails_helper'

RSpec.describe Admin::UsersController, type: :request do
  let(:admin_user) { create(:user, role: :admin) }
  let(:normal_user) { create(:user, role: :normal_user) }
  let(:other_user) { create(:user, role: :normal_user, name: 'Other User') }

  before { sign_in admin_user, scope: :user }

  describe 'GET /admin/users' do
    before do
      # Create users with short URLs to test counter cache
      3.times { create(:short_url, user: normal_user) }
      2.times { create(:short_url, user: other_user) }
    end

    it 'shows users index page' do
      get '/admin/users'
      expect(response).to have_http_status(:success)
    end

    it 'displays user statistics' do
      get '/admin/users'
      expect(response.body).to include('総ユーザー数')
      expect(response.body).to include('管理者')
      expect(response.body).to include('一般ユーザー')
    end

    it 'displays users with counter cache data' do
      get '/admin/users'
      expect(response.body).to include('3個') # normal_user's short URLs count
      expect(response.body).to include('2個') # other_user's short URLs count
    end

    it 'displays total visit counts' do
      # Update visit counts
      normal_user.short_urls.first.update!(visit_count: 10)
      other_user.short_urls.first.update!(visit_count: 5)

      get '/admin/users'
      expect(response.body).to include('総アクセス: 10回')
      expect(response.body).to include('総アクセス: 5回')
    end

    it 'supports search functionality' do
      get '/admin/users', params: { search: 'Other' }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Other User')
      expect(response.body).not_to include(normal_user.email)
    end

    it 'supports role filtering' do
      get '/admin/users', params: { role: 'admin' }
      expect(response).to have_http_status(:success)
      expect(response.body).to include(admin_user.email)
      expect(response.body).not_to include(normal_user.email)
    end

    context 'when not admin' do
      before { sign_in normal_user, scope: :user }

      xit 'redirects to root with error' do
        get '/admin/users'
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('管理者権限が必要です。')
      end
    end
  end

  describe 'GET /admin/users/:id' do
    it 'shows user detail page' do
      get "/admin/users/#{normal_user.id}"
      expect(response).to have_http_status(:success)
    end

    it 'displays user information' do
      get "/admin/users/#{normal_user.id}"
      expect(response.body).to include(normal_user.email)
      expect(response.body).to include(normal_user.display_name)
    end
  end

  describe 'PATCH /admin/users/:id' do
    it 'updates user information' do
      patch "/admin/users/#{normal_user.id}", params: {
        user: {
          name: 'Updated Name',
          role: 'admin'
        }
      }

      expect(response).to redirect_to(admin_user_path(normal_user))
      expect(flash[:notice]).to include('更新しました')

      normal_user.reload
      expect(normal_user.name).to eq('Updated Name')
      expect(normal_user.admin?).to be_truthy
    end

    it 'handles validation errors' do
      patch "/admin/users/#{normal_user.id}", params: {
        user: {
          email: '' # Invalid email
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /admin/users/:id' do
    it 'deletes user successfully' do
      user_to_delete = create(:user, role: :normal_user)

      expect {
        delete "/admin/users/#{user_to_delete.id}"
      }.to change { User.count }.by(-1)

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:notice]).to include('削除しました')
    end

    it 'prevents admin from deleting themselves' do
      expect {
        delete "/admin/users/#{admin_user.id}"
      }.not_to change { User.count }

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to include('自分自身のアカウントは削除できません')
    end

    it 'handles deletion errors gracefully' do
      user_to_delete = create(:user, role: :normal_user)

      # Mock deletion error
      allow(User).to receive(:find).with(user_to_delete.id.to_s).and_return(user_to_delete)
      allow(user_to_delete).to receive(:destroy!).and_raise(StandardError.new('Test error'))

      delete "/admin/users/#{user_to_delete.id}"

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to include('削除に失敗しました')
    end
  end
end
