require 'rails_helper'

RSpec.describe Admin::DashboardController, type: :controller do
  let(:admin) { create(:user, role: 'admin') }

  before do
    sign_in admin
  end

  describe 'GET #index' do
    let(:system_stats_service) { instance_double(Admin::SystemStatsService) }
    let(:server_monitor_service) { instance_double(Admin::ServerMonitorService) }
    let(:mock_stats) do
      {
        users: { total: 10, admin: 1, normal: 9 },
        short_urls: { total: 100, total_visits: 1000 },
        system: { uptime: { formatted: '1日' } }
      }
    end
    let(:mock_monitor) do
      {
        system: {
          memory: { usage_percent: 50, status: 'good' },
          disk: { usage_percent: 30, status: 'good' },
          cpu: { usage_percent: 25, status: 'good' }
        }
      }
    end

    before do
      allow(Admin::SystemStatsService).to receive(:new).and_return(system_stats_service)
      allow(Admin::ServerMonitorService).to receive(:new).and_return(server_monitor_service)
      allow(system_stats_service).to receive(:call).and_return(mock_stats)
      allow(server_monitor_service).to receive(:call).and_return(mock_monitor)
    end

    it 'システム統計を取得すること' do
      get :index
      expect(assigns(:system_stats)).to eq(mock_stats)
      expect(assigns(:server_monitor)).to eq(mock_monitor)
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:index)
    end

    it 'システム健康状態をチェックすること' do
      get :index
      system_health = assigns(:system_health)
      expect(system_health).to have_key(:database)
      expect(system_health).to have_key(:redis)
      expect(system_health).to have_key(:storage)
    end
  end

  context '管理者権限のないユーザー' do
    let(:normal_user) { create(:user, role: 'normal_user') }

    before do
      sign_in normal_user
    end

    it '管理者ログインページにリダイレクトすること' do
      get :index
      expect(response).to redirect_to(admin_login_path)
    end
  end
end
