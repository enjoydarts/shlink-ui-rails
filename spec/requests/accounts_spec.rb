require 'rails_helper'

RSpec.describe 'Accounts', type: :request do
  let(:user) { create(:user) }
  let(:oauth_user) { create(:user, :from_omniauth) }

  describe 'GET /account' do
    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされる' do
        get account_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン済みの場合' do
      before do
        sign_in user, scope: :user
      end

      it '正常にアカウント設定画面が表示される' do
        get account_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('アカウント設定')
        expect(response.body).to include(user.display_name)
        expect(response.body).to include(user.email)
      end

      it 'タブナビゲーション要素が含まれる' do
        get account_path
        expect(response.body).to include('data-controller="account-tabs"')
        expect(response.body).to include('data-tab="basic"')
        expect(response.body).to include('data-tab="security"')
        expect(response.body).to include('data-tab="danger"')
      end

      it 'アカウント削除モーダル要素が含まれる' do
        get account_path
        expect(response.body).to include('data-controller="account-delete"')
        expect(response.body).to include('アカウントの削除')
      end

      it 'フラッシュメッセージが重複表示されない' do
        get account_path
        # render_flash_messagesが2回呼ばれていないことを確認
        flash_message_count = response.body.scan(/render_flash_messages/).length
        expect(flash_message_count).to eq(0) # アカウント設定画面では呼ばれない
      end
    end

    context 'OAuthユーザーの場合' do
      before do
        sign_in oauth_user, scope: :user
      end

      it 'OAuth用のUI要素が表示される' do
        get account_path
        expect(response.body).to include('Google認証ユーザー')
        expect(response.body).to include('data-account-delete-is-oauth-user-value="true"')
      end

      it 'パスワード設定のUI要素が表示される' do
        get account_path
        expect(response.body).to include('パスワード設定')
        expect(response.body).to include('Google認証ユーザーのため、現在のパスワードは不要です')
      end

      it 'メールアドレス変更制限の説明が表示される' do
        get account_path
        expect(response.body).to include('Google認証ユーザーのメールアドレス変更について')
        expect(response.body).to include('Google認証でログインしているため、メールアドレスの変更はできません')
      end
    end

    context '通常ユーザーの場合' do
      before do
        sign_in user, scope: :user
      end

      it 'パスワード変更のUI要素が表示される' do
        get account_path
        expect(response.body).to include('パスワード変更')
        expect(response.body).to include('data-account-delete-is-oauth-user-value="false"')
      end
    end
  end

  describe 'アクセシビリティ' do
    before do
      sign_in user, scope: :user
    end

    it '適切なARIA属性が設定されている' do
      get account_path
      expect(response.body).to include('role="tablist"')
      expect(response.body).to include('role="tab"')
      expect(response.body).to include('role="tabpanel"')
      expect(response.body).to include('aria-selected="true"')
      expect(response.body).to include('aria-selected="false"')
      expect(response.body).to include('aria-hidden="true"')
      expect(response.body).to include('aria-hidden="false"')
    end

    it 'アクセシビリティラベルが設定されている' do
      get account_path
      expect(response.body).to include('aria-label="アカウント設定"')
      expect(response.body).to include('aria-controls="basic-panel"')
      expect(response.body).to include('aria-controls="security-panel"')
      expect(response.body).to include('aria-controls="danger-panel"')
    end
  end

  describe 'レスポンシブデザイン要素' do
    before do
      sign_in user, scope: :user
    end

    it 'モバイル用の省略ラベルが含まれる' do
      get account_path
      expect(response.body).to include('class="sm:hidden">基本</span>')
      expect(response.body).to include('class="sm:hidden">安全</span>')
      expect(response.body).to include('class="sm:hidden">危険</span>')
    end

    it 'デスクトップ用の完全ラベルが含まれる' do
      get account_path
      expect(response.body).to include('class="hidden sm:inline">基本設定</span>')
      expect(response.body).to include('class="hidden sm:inline">セキュリティ</span>')
      expect(response.body).to include('class="hidden sm:inline">危険な操作</span>')
    end
  end

  describe 'セキュリティ' do
    context '未認証ユーザー' do
      it 'アカウント設定画面にアクセスできない' do
        get account_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '認証済みユーザー' do
      before do
        sign_in user, scope: :user
      end

      it '自分のアカウント情報のみ表示される' do
        other_user = create(:user, email: 'other@example.com', name: 'Other User')
        get account_path

        expect(response.body).to include(user.email)
        expect(response.body).to include(user.display_name)
        expect(response.body).not_to include(other_user.email)
        expect(response.body).not_to include(other_user.display_name)
      end
    end
  end

  describe 'パフォーマンス' do
    before do
      sign_in user, scope: :user
    end

    it '適切なHTTPヘッダーが設定される' do
      get account_path
      expect(response.headers['Content-Type']).to include('text/html')
      expect(response.headers['Cache-Control']).to include('must-revalidate') # キャッシュ制御
    end

    it 'レスポンス時間が適切' do
      start_time = Time.current
      get account_path
      end_time = Time.current

      response_time = end_time - start_time
      expect(response_time).to be < 1.0 # 1秒未満
    end
  end
end
