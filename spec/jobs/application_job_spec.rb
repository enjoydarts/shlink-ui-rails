# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  let(:test_job_class) do
    Class.new(ApplicationJob) do
      def perform
        # Test job implementation
      end
    end
  end

  let(:test_job_instance) { test_job_class.new }

  describe 'ベースジョブクラス' do
    it 'ActiveJob::Baseを継承していること' do
      expect(described_class.superclass).to eq(ActiveJob::Base)
    end

    it 'インスタンス化できること' do
      expect(test_job_instance).to be_a(ApplicationJob)
    end
  end

  describe 'ConfigShortcutsの組み込み' do
    it 'ConfigShortcutsモジュールをインクルードしていること' do
      expect(described_class.included_modules).to include(ConfigShortcuts)
    end

    it '設定ショートカットメソッドにアクセスできること' do
      expect(test_job_instance).to respond_to(:shlink_base_url)
      expect(test_job_instance).to respond_to(:shlink_api_key)
      expect(test_job_instance).to respond_to(:email_adapter)
    end

    it '設定ショートカットメソッドを呼び出せること' do
      # 実際の設定アクセスを避けるためApplicationConfigをモック
      allow(ApplicationConfig).to receive(:string).with('shlink.base_url', anything).and_return('test-url')

      expect(test_job_instance.shlink_base_url).to eq('test-url')
    end
  end

  describe 'ジョブ設定' do
    it 'ActiveJob::Baseを使用するよう設定されていること' do
      expect(test_job_class.superclass).to eq(ApplicationJob)
      expect(ApplicationJob.superclass).to eq(ActiveJob::Base)
    end

    it 'ジョブをキューに追加できること', :aggregate_failures do
      ActiveJob::Base.queue_adapter = :test
      expect {
        test_job_class.perform_later
      }.to have_enqueued_job(test_job_class)
    end
  end
end
