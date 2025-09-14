require 'rails_helper'

RSpec.describe 'Counter Cache', type: :model do
  let(:user) { create(:user) }

  describe 'short_urls_count counter cache' do
    it 'increments when a short_url is created' do
      expect { create(:short_url, user: user) }
        .to change { user.reload.short_urls_count }.by(1)
    end

    it 'decrements when a short_url is destroyed' do
      short_url = create(:short_url, user: user)
      user.reload

      expect { short_url.destroy }
        .to change { user.reload.short_urls_count }.by(-1)
    end

    it 'maintains accurate count with multiple operations' do
      expect(user.short_urls_count).to eq(0)

      # Create multiple short URLs
      3.times { create(:short_url, user: user) }
      expect(user.reload.short_urls_count).to eq(3)

      # Delete one
      user.short_urls.first.destroy
      expect(user.reload.short_urls_count).to eq(2)

      # Create another
      create(:short_url, user: user)
      expect(user.reload.short_urls_count).to eq(3)
    end

    it 'matches actual association count' do
      5.times { create(:short_url, user: user) }

      expect(user.reload.short_urls_count).to eq(user.short_urls.count)
    end
  end
end
