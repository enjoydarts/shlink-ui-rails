require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /home" do
    context "when user is not logged in" do
      it "returns http success" do
        get "/home"
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is logged in" do
      let(:user) { create(:user) }

      before do
        sign_in user, scope: :user
      end

      it "redirects to dashboard" do
        get "/home"
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
