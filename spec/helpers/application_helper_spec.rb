require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#render_flash_messages' do
    context 'フラッシュメッセージがある場合' do
      before do
        flash[:notice] = 'テスト成功メッセージ'
        flash[:alert] = 'テストエラーメッセージ'
      end

      it 'フラッシュメッセージパーシャルがレンダリングされる' do
        expect(helper).to receive(:render).with('shared/flash_messages')
        helper.render_flash_messages
      end
    end

    context 'フラッシュメッセージがない場合' do
      it 'nilが返される' do
        expect(helper.render_flash_messages).to be_nil
      end
    end
  end

  describe '#render_form_errors' do
    let(:user) { build(:user, email: '', password: '') }

    before do
      user.valid? # バリデーションエラーを発生させる
    end

    context 'エラーがある場合' do
      it 'フォームエラーパーシャルがレンダリングされる' do
        expect(helper).to receive(:render).with('shared/form_errors', errors: user.errors)
        helper.render_form_errors(user)
      end
    end

    context 'エラーがない場合' do
      let(:valid_user) { build(:user) }

      before do
        valid_user.valid?
      end

      it 'nilが返される' do
        expect(helper.render_form_errors(valid_user)).to be_nil
      end
    end

    context 'エラー配列が直接渡された場合' do
      it 'エラー配列が使用される' do
        errors_array = user.errors.full_messages
        expect(helper).to receive(:render).with('shared/form_errors', errors: errors_array)
        helper.render_form_errors(errors_array)
      end
    end
  end

  describe '#render_field_error' do
    let(:field_errors) { [ 'フィールドエラー1', 'フィールドエラー2' ] }

    context 'フィールドエラーがある場合' do
      it 'フィールドエラーパーシャルがレンダリングされる' do
        expect(helper).to receive(:render).with('shared/field_error', errors: field_errors)
        helper.render_field_error(field_errors)
      end
    end

    context 'フィールドエラーがない場合' do
      it 'nilが返される' do
        expect(helper.render_field_error([])).to be_nil
      end
    end
  end

  describe '#nav_link_class' do
    context 'mypageページの場合' do
      before do
        allow(helper).to receive(:request).and_return(double(path: '/mypage'))
      end

      it 'mypageがアクティブな場合、アクティブクラスが返される' do
        expected_class = "inline-flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm"
        expect(helper.nav_link_class('mypage')).to eq(expected_class)
      end

      it 'dashboardが非アクティブな場合、非アクティブクラスが返される' do
        expected_class = "inline-flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-white/50 dark:hover:bg-gray-700/50"
        expect(helper.nav_link_class('dashboard')).to eq(expected_class)
      end
    end

    context 'dashboardページの場合' do
      before do
        allow(helper).to receive(:request).and_return(double(path: '/dashboard'))
      end

      it 'dashboardがアクティブな場合、アクティブクラスが返される' do
        expected_class = "inline-flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm"
        expect(helper.nav_link_class('dashboard')).to eq(expected_class)
      end
    end

    context 'ルートパスの場合' do
      before do
        allow(helper).to receive(:request).and_return(double(path: '/'))
      end

      it 'dashboardがアクティブとして扱われる' do
        expected_class = "inline-flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm"
        expect(helper.nav_link_class('dashboard')).to eq(expected_class)
      end
    end

    context 'short_urlsパスの場合' do
      before do
        allow(helper).to receive(:request).and_return(double(path: '/short_urls/new'))
      end

      it 'dashboardがアクティブとして扱われる' do
        expected_class = "inline-flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm"
        expect(helper.nav_link_class('dashboard')).to eq(expected_class)
      end
    end

    context '未知のページの場合' do
      before do
        allow(helper).to receive(:request).and_return(double(path: '/unknown'))
      end

      it '全てのページが非アクティブクラスになる' do
        expected_class = "inline-flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-white/50 dark:hover:bg-gray-700/50"
        expect(helper.nav_link_class('dashboard')).to eq(expected_class)
        expect(helper.nav_link_class('mypage')).to eq(expected_class)
      end
    end
  end
end
