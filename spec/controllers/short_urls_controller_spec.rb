require 'rails_helper'

RSpec.describe ShortUrlsController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end
  describe 'GET #new' do
    it 'HTTP成功ステータスを返す' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it '新しいShortenFormを@shortenに割り当てる' do
      get :new
      expect(assigns(:shorten)).to be_a(ShortenForm)
      expect(assigns(:shorten).long_url).to be_nil
    end

    it 'nilを@resultに割り当てる' do
      get :new
      expect(assigns(:result)).to be_nil
    end

    it 'newテンプレートをレンダリングする' do
      get :new
      expect(response).to render_template('new')
    end
  end

  describe 'GET #test' do
    it 'HTTP成功ステータスを返す' do
      get :test
      expect(response).to have_http_status(:success)
    end

    it 'testテンプレートをレンダリングする' do
      get :test
      expect(response).to render_template('test')
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        shorten_form: {
          long_url: 'https://example.com/very/long/url',
          slug: 'custom-slug'
        }
      }
    end

    let(:valid_params_with_tags) do
      {
        shorten_form: {
          long_url: 'https://example.com/very/long/url',
          slug: 'custom-slug',
          tags: 'tag1, tag2, tag3'
        }
      }
    end

    let(:invalid_params) do
      {
        shorten_form: {
          long_url: 'invalid-url',
          slug: 'custom-slug'
        }
      }
    end

    let(:shlink_response) do
      {
        'shortUrl' => 'https://shlink.example.com/abc123',
        'shortCode' => 'abc123',
        'longUrl' => 'https://example.com/very/long/url',
        'dateCreated' => '2025-01-01T00:00:00+00:00'
      }
    end

    context '有効なパラメータの場合' do
      let(:mock_client) { instance_double(Shlink::CreateShortUrlService) }

      before do
        allow(Shlink::CreateShortUrlService).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:call)
          .with(long_url: 'https://example.com/very/long/url', slug: 'custom-slug', valid_until: nil, max_visits: nil, tags: [])
          .and_return(shlink_response)
      end

      context 'リクエスト形式がHTMLの場合' do
        it '短縮URLを作成してリダイレクトする' do
          post :create, params: valid_params

          expect(assigns(:shorten)).to be_valid
          expect(assigns(:result)).to eq(short_url: 'https://shlink.example.com/abc123')
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to eq('短縮しました')
        end
      end

      context 'リクエスト形式がTurbo Streamの場合' do
        it '短縮URLを作成してturbo streamをレンダリングする' do
          post :create, params: valid_params, format: :turbo_stream

          expect(assigns(:shorten)).to be_valid
          expect(assigns(:result)).to eq(short_url: 'https://shlink.example.com/abc123')
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        end
      end

      context 'slugが空の場合' do
        let(:params_with_empty_slug) do
          {
            shorten_form: {
              long_url: 'https://example.com/very/long/url',
              slug: ''
            }
          }
        end

        before do
          allow(mock_client).to receive(:call)
            .with(long_url: 'https://example.com/very/long/url', slug: '', valid_until: nil, max_visits: nil, tags: [])
            .and_return(shlink_response)
        end

        it '空のslugで短縮URLを作成する' do
          post :create, params: params_with_empty_slug

          expect(assigns(:result)).to eq(short_url: 'https://shlink.example.com/abc123')
          expect(response).to redirect_to(root_path)
        end
      end

      context 'タグ付きパラメータの場合' do
        let(:mock_client_with_tags) { instance_double(Shlink::CreateShortUrlService) }

        before do
          allow(Shlink::CreateShortUrlService).to receive(:new).and_return(mock_client_with_tags)
          allow(mock_client_with_tags).to receive(:call)
            .with(long_url: 'https://example.com/very/long/url', slug: 'custom-slug', valid_until: nil, max_visits: nil, tags: [ 'tag1', 'tag2', 'tag3' ])
            .and_return(shlink_response)
        end

        it 'タグ付きで短縮URLを作成する' do
          post :create, params: valid_params_with_tags

          expect(assigns(:shorten)).to be_valid
          expect(assigns(:result)).to eq(short_url: 'https://shlink.example.com/abc123')
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to eq('短縮しました')
        end
      end

      context '空のタグパラメータの場合' do
        let(:params_with_empty_tags) do
          {
            shorten_form: {
              long_url: 'https://example.com/very/long/url',
              slug: 'custom-slug',
              tags: ''
            }
          }
        end

        let(:mock_client_empty_tags) { instance_double(Shlink::CreateShortUrlService) }

        before do
          allow(Shlink::CreateShortUrlService).to receive(:new).and_return(mock_client_empty_tags)
          allow(mock_client_empty_tags).to receive(:call)
            .with(long_url: 'https://example.com/very/long/url', slug: 'custom-slug', valid_until: nil, max_visits: nil, tags: [])
            .and_return(shlink_response)
        end

        it '空のタグで短縮URLを作成する' do
          post :create, params: params_with_empty_tags

          expect(assigns(:result)).to eq(short_url: 'https://shlink.example.com/abc123')
          expect(response).to redirect_to(root_path)
        end
      end
    end

    context '無効なパラメータの場合' do
      context 'リクエスト形式がHTMLの場合' do
        it 'unprocessable entityステータスでnewテンプレートをレンダリングする' do
          post :create, params: invalid_params

          expect(assigns(:shorten)).not_to be_valid
          expect(assigns(:result)).to be_nil
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template('new')
        end
      end

      context 'リクエスト形式がTurbo Streamの場合' do
        it 'バリデーションエラーでturbo streamをレンダリングする' do
          post :create, params: invalid_params, format: :turbo_stream

          expect(assigns(:shorten)).not_to be_valid
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        end
      end
    end

    context 'Shlink APIがエラーを返す場合' do
      let(:mock_client) { instance_double(Shlink::CreateShortUrlService) }

      before do
        # Devise認証をバイパス
        allow(controller).to receive(:authenticate_user!).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)

        allow(Shlink::CreateShortUrlService).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:call)
          .and_raise(Shlink::Error, 'API connection failed')
      end

      context 'リクエスト形式がHTMLの場合' do
        it 'bad gatewayステータスでnewテンプレートをレンダリングする' do
          post :create, params: valid_params

          expect(flash[:alert]).to eq('API connection failed')
          expect(response).to have_http_status(:bad_gateway)
          expect(response).to render_template('new')
        end
      end

      context 'リクエスト形式がTurbo Streamの場合' do
        it 'エラーメッセージでturbo streamをレンダリングする' do
          post :create, params: valid_params, format: :turbo_stream

          expect(flash[:alert]).to eq('API connection failed')
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        end
      end
    end

    context 'Shlink APIが特定のエラーメッセージを返す場合' do
      let(:mock_client) { instance_double(Shlink::CreateShortUrlService) }

      before do
        allow(Shlink::CreateShortUrlService).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:call)
          .and_raise(Shlink::Error, 'Custom slug already exists')
      end

      it '特定のエラーメッセージを表示する' do
        post :create, params: valid_params

        expect(flash[:alert]).to eq('Custom slug already exists')
        expect(response).to have_http_status(:bad_gateway)
      end
    end
  end

  describe 'GET #edit' do
    let(:short_url) { create(:short_url, user: user, short_code: 'test123') }

    context '存在するshort_codeの場合' do
      it 'HTTP成功ステータスを返す' do
        get :edit, params: { short_code: 'test123' }, format: :turbo_stream
        expect(response).to have_http_status(:success)
      end

      it 'EditShortUrlFormを@edit_formに割り当てる' do
        get :edit, params: { short_code: 'test123' }, format: :turbo_stream
        expect(assigns(:edit_form)).to be_a(EditShortUrlForm)
        expect(assigns(:edit_form).short_code).to eq('test123')
      end

      it 'ShortUrlを@short_urlに割り当てる' do
        get :edit, params: { short_code: 'test123' }, format: :turbo_stream
        expect(assigns(:short_url)).to eq(short_url)
      end
    end

    context '存在しないshort_codeの場合' do
      it 'not foundステータスを返す' do
        get :edit, params: { short_code: 'nonexistent' }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'エラーメッセージを返す' do
        get :edit, params: { short_code: 'nonexistent' }, format: :json
        expect(JSON.parse(response.body)['message']).to eq('指定された短縮URLが見つかりません')
      end
    end

    context '他ユーザーのshort_urlの場合' do
      let(:other_user) { create(:user) }
      let!(:other_short_url) { create(:short_url, user: other_user, short_code: 'other123') }

      it 'not foundステータスを返す' do
        get :edit, params: { short_code: 'other123' }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH #update' do
    let(:short_url) { create(:short_url, user: user, short_code: 'test123') }
    let(:mock_service) { instance_double(Shlink::UpdateShortUrlService) }
    let(:shlink_response) do
      {
        'shortCode' => 'test123',
        'shortUrl' => 'https://shlink.example.com/test123',
        'longUrl' => 'https://updated.example.com',
        'title' => 'Updated Title',
        'tags' => [ 'tag1', 'tag2' ]
      }
    end

    before do
      allow(Shlink::UpdateShortUrlService).to receive(:new).and_return(mock_service)
    end

    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          short_code: 'test123',
          edit_short_url_form: {
            title: 'Updated Title',
            long_url: 'https://updated.example.com',
            tags: 'tag1, tag2'
          }
        }
      end

      before do
        allow(mock_service).to receive(:call).and_return(shlink_response)
      end

      it 'HTTP成功ステータスを返す' do
        patch :update, params: valid_params, format: :turbo_stream
        expect(response).to have_http_status(:success)
      end

      it 'Shlink APIを呼び出す' do
        expect(mock_service).to receive(:call).with(
          short_code: 'test123',
          title: 'Updated Title',
          long_url: 'https://updated.example.com',
          tags: [ 'tag1', 'tag2' ]
        )

        patch :update, params: valid_params, format: :turbo_stream
      end

      it 'ローカルDBを更新する' do
        patch :update, params: valid_params, format: :turbo_stream

        short_url.reload
        expect(short_url.title).to eq('Updated Title')
        expect(short_url.long_url).to eq('https://updated.example.com')
      end

      context 'JSON形式のリクエストの場合' do
        it '成功メッセージを返す' do
          patch :update, params: valid_params, format: :json

          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)['success']).to be true
          expect(JSON.parse(response.body)['message']).to eq('短縮URLを更新しました')
        end
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) do
        {
          short_code: 'test123',
          edit_short_url_form: {
            long_url: 'invalid-url'
          }
        }
      end

      it 'unprocessable entityステータスを返す' do
        patch :update, params: invalid_params, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'エラーメッセージを返す' do
        patch :update, params: invalid_params, format: :json

        response_body = JSON.parse(response.body)
        expect(response_body['success']).to be false
        expect(response_body['message']).to eq('入力内容に問題があります')
        expect(response_body['errors']).to be_present
      end
    end

    context 'Shlink APIエラーの場合' do
      let(:valid_params) do
        {
          short_code: 'test123',
          edit_short_url_form: {
            title: 'Updated Title'
          }
        }
      end

      before do
        allow(mock_service).to receive(:call)
          .and_raise(Shlink::Error, 'API connection failed')
      end

      it 'bad gatewayステータスを返す' do
        patch :update, params: valid_params, format: :json
        expect(response).to have_http_status(:bad_gateway)
      end

      it 'エラーメッセージを返す' do
        patch :update, params: valid_params, format: :json

        response_body = JSON.parse(response.body)
        expect(response_body['success']).to be false
        expect(response_body['message']).to include('API connection failed')
      end
    end

    context '存在しないshort_codeの場合' do
      let(:params) do
        {
          short_code: 'nonexistent',
          edit_short_url_form: {
            title: 'Updated Title'
          }
        }
      end

      it 'not foundステータスを返す' do
        patch :update, params: params, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context '他ユーザーのshort_urlの場合' do
      let(:other_user) { create(:user) }
      let!(:other_short_url) { create(:short_url, user: other_user, short_code: 'other123') }
      let(:params) do
        {
          short_code: 'other123',
          edit_short_url_form: {
            title: 'Updated Title'
          }
        }
      end

      it 'not foundステータスを返す' do
        patch :update, params: params, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'プライベートメソッド' do
    describe '#shorten_params' do
      let(:params) do
        ActionController::Parameters.new(
          shorten_form: {
            long_url: 'https://example.com',
            slug: 'test-slug',
            tags: 'tag1, tag2',
            other_param: 'should_be_filtered'
          },
          other_key: 'should_be_filtered'
        )
      end

      before do
        allow(controller).to receive(:params).and_return(params)
      end

      it 'shorten_formからlong_url、slug、tagsを許可する' do
        permitted_params = controller.send(:shorten_params)

        expect(permitted_params).to eq(
          ActionController::Parameters.new(
            long_url: 'https://example.com',
            slug: 'test-slug',
            tags: 'tag1, tag2'
          ).permit!
        )
      end
    end

    describe '#edit_short_url_params' do
      let(:params) do
        ActionController::Parameters.new(
          edit_short_url_form: {
            title: 'Test Title',
            long_url: 'https://example.com',
            valid_until: '2024-12-31T23:59:59',
            max_visits: '100',
            tags: 'tag1, tag2',
            custom_slug: 'custom-slug',
            other_param: 'should_be_filtered'
          },
          other_key: 'should_be_filtered'
        )
      end

      before do
        allow(controller).to receive(:params).and_return(params)
      end

      it 'edit_short_url_formから許可されたパラメータのみを返す' do
        permitted_params = controller.send(:edit_short_url_params)

        expect(permitted_params).to eq(
          ActionController::Parameters.new(
            title: 'Test Title',
            long_url: 'https://example.com',
            valid_until: '2024-12-31T23:59:59',
            max_visits: '100',
            tags: 'tag1, tag2',
            custom_slug: 'custom-slug'
          ).permit!
        )
      end
    end
  end

  describe '認証なしの場合' do
    before do
      sign_out user
    end

    it 'newアクションはログインページにリダイレクトする' do
      get :new
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'createアクションはログインページにリダイレクトする' do
      post :create, params: { shorten_form: { long_url: 'https://example.com' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'qr_codeアクションはログインページにリダイレクトする' do
      get :qr_code, params: { short_code: 'test' }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
