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
          .with(long_url: 'https://example.com/very/long/url', slug: 'custom-slug', valid_until: nil, max_visits: nil)
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
            .with(long_url: 'https://example.com/very/long/url', slug: '', valid_until: nil, max_visits: nil)
            .and_return(shlink_response)
        end

        it '空のslugで短縮URLを作成する' do
          post :create, params: params_with_empty_slug

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
        allow(Shlink::CreateShortUrlService).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:call)
          .and_raise(Shlink::Error, 'API connection failed')
      end

      context 'リクエスト形式がHTMLの場合' do
        it 'bad gatewayステータスでnewテンプレートをレンダリングする' do
          post :create, params: valid_params

          expect(assigns(:error)).to eq('API connection failed')
          expect(response).to have_http_status(:bad_gateway)
          expect(response).to render_template('new')
        end
      end

      context 'リクエスト形式がTurbo Streamの場合' do
        it 'エラーメッセージでturbo streamをレンダリングする' do
          post :create, params: valid_params, format: :turbo_stream

          expect(assigns(:error)).to eq('API connection failed')
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

        expect(assigns(:error)).to eq('Custom slug already exists')
        expect(response).to have_http_status(:bad_gateway)
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
            other_param: 'should_be_filtered'
          },
          other_key: 'should_be_filtered'
        )
      end

      before do
        allow(controller).to receive(:params).and_return(params)
      end

      it 'shorten_formからlong_urlとslugのみを許可する' do
        permitted_params = controller.send(:shorten_params)

        expect(permitted_params).to eq(
          ActionController::Parameters.new(
            long_url: 'https://example.com',
            slug: 'test-slug'
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
