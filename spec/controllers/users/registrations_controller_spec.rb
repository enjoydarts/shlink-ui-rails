# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :request do
  let(:user) { create(:user) }
  let(:oauth_user) { create(:user, :from_oauth, provider: 'google_oauth2') }

  describe 'POST #create' do
    let(:valid_params) do
      {
        user: {
          name: 'Test User',
          email: 'newuser@example.com',
          password: 'Password123!',
          password_confirmation: 'Password123!'
        }
      }
    end

    context 'CAPTCHA検証が成功する場合' do
      before do
        allow_any_instance_of(described_class).to receive(:verify_captcha).and_return(true)
        allow_any_instance_of(described_class).to receive(:verify_legal_agreement).and_return(true)
      end

      it 'ユーザーを作成すること' do
        expect {
          post user_registration_path, params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(root_path)
      end
    end

    context 'CAPTCHA検証が失敗する場合' do
      before do
        allow_any_instance_of(described_class).to receive(:verify_captcha).and_return(false)
      end

      it '新規登録画面を再表示すること' do
        expect {
          post user_registration_path, params: valid_params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end
    end

    context '無効なパラメータの場合' do
      before do
        allow_any_instance_of(described_class).to receive(:verify_captcha).and_return(true)
      end

      it 'バリデーションエラーを表示すること' do
        invalid_params = valid_params
        invalid_params[:user][:email] = ''

        expect {
          post user_registration_path, params: invalid_params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'キャッシュヘッダーの確認' do
      before do
        allow_any_instance_of(described_class).to receive(:verify_captcha).and_return(false)
      end

      it 'キャッシュ無効化ヘッダーが設定されること' do
        post user_registration_path, params: valid_params

        expect(response.headers['Cache-Control']).to include('no-store')
      end
    end
  end

  describe 'GET #new' do
    it 'キャッシュ無効化ヘッダーが設定されること' do
      get new_user_registration_path

      expect(response.headers['Cache-Control']).to include('no-store')
    end
  end

  describe 'PUT #update' do
    before do
      sign_in user, scope: :user
    end

    context '通常ユーザーの場合' do
      context '名前のみ更新' do
        it 'アカウント情報を更新すること' do
          put user_registration_path, params: {
            user: {
              name: 'Updated Name',
              current_password: 'Password123!'
            }
          }

          expect(response).to redirect_to(account_path)
          expect(flash[:notice]).to eq('アカウント情報を正常に更新しました。')
          expect(user.reload.name).to eq('Updated Name')
        end
      end

      context 'パスワード更新' do
        it 'パスワードを更新すること' do
          put user_registration_path, params: {
            user: {
              password: 'NewPassword123!',
              password_confirmation: 'NewPassword123!',
              current_password: 'Password123!'
            }
          }

          expect(response).to redirect_to(account_path)
          expect(flash[:notice]).to eq('アカウント情報を正常に更新しました。')
        end
      end

      context '現在のパスワードが間違っている場合' do
        it 'アカウントページにリダイレクトすること' do
          put user_registration_path, params: {
            user: {
              name: 'Updated Name',
              current_password: 'wrongpassword'
            }
          }

          expect(response).to redirect_to(account_path)
        end
      end
    end

    context 'OAuthユーザーの場合' do
      before do
        sign_out :user
        sign_in oauth_user, scope: :user
      end

      context 'プロフィール更新' do
        it '名前を更新できること' do
          put user_registration_path, params: {
            user: {
              name: 'Updated OAuth Name'
            }
          }

          expect(response).to redirect_to(account_path)
          expect(flash[:notice]).to eq('アカウント情報を正常に更新しました。')
          expect(oauth_user.reload.name).to eq('Updated OAuth Name')
        end
      end

      context 'メールアドレス変更を試行' do
        it 'エラーメッセージを表示すること' do
          put user_registration_path, params: {
            user: {
              email: 'newemail@example.com'
            }
          }

          expect(response).to redirect_to(account_path)
          expect(flash[:alert]).to include('Google認証ユーザーはメールアドレスを変更できません')
        end
      end

      context 'パスワード設定（初回）' do
        it 'パスワードを設定できること' do
          put user_registration_path, params: {
            user: {
              password: 'NewPassword123!',
              password_confirmation: 'NewPassword123!'
            }
          }

          expect(response).to redirect_to(account_path)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context '通常ユーザーの場合' do
      before do
        sign_in user, scope: :user
      end

      it '正しいパスワードでアカウントを削除できること' do
        expect {
          delete user_registration_path, params: {
            user: {
              current_password: 'Password123!'
            }
          }
        }.to change(User, :count).by(-1)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to be_present
      end

      it '間違ったパスワードでは削除できないこと' do
        expect {
          delete user_registration_path, params: {
            user: {
              current_password: 'wrongpassword'
            }
          }
        }.not_to change(User, :count)

        expect(response).to redirect_to(account_path)
        expect(flash[:alert]).to be_present
      end
    end

    context 'OAuthユーザーの場合' do
      before do
        sign_in oauth_user, scope: :user
      end

      it '正しい確認文字でアカウントを削除できること' do
        expect {
          delete user_registration_path, params: {
            user: {
              delete_confirmation: '削除'
            }
          }
        }.to change(User, :count).by(-1)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to be_present
      end

      it '間違った確認文字では削除できないこと' do
        expect {
          delete user_registration_path, params: {
            user: {
              delete_confirmation: '間違い'
            }
          }
        }.not_to change(User, :count)

        expect(response).to redirect_to(account_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
