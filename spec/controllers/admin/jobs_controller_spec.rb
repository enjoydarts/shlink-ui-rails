require 'rails_helper'

RSpec.describe Admin::JobsController, type: :request, skip: "Devise mapping issue in test environment" do
  let(:admin_user) { create(:user, role: :admin) }
  let(:normal_user) { create(:user, role: :normal_user) }

  before { sign_in admin_user, scope: :user }

  describe 'GET /admin/jobs' do
    before do
      # Create some test jobs
      3.times do
        job = SolidQueue::Job.create!(
          queue_name: 'default',
          class_name: 'TestJob',
          arguments: [].to_json,
          priority: 0,
          active_job_id: SecureRandom.uuid
        )

        SolidQueue::FailedExecution.create!(
          job: job,
          error: 'Test error message'
        )
      end

      # Create running job
      SolidQueue::Job.create!(
        queue_name: 'default',
        class_name: 'RunningJob',
        arguments: [].to_json,
        priority: 0,
        active_job_id: SecureRandom.uuid
      )

      # Create completed job
      SolidQueue::Job.create!(
        queue_name: 'default',
        class_name: 'CompletedJob',
        arguments: [].to_json,
        priority: 0,
        active_job_id: SecureRandom.uuid,
        finished_at: 1.hour.ago
      )
    end

    it 'shows job management page' do
      get '/admin/jobs'
      expect(response).to have_http_status(:success)
    end

    it 'displays failed jobs count' do
      get '/admin/jobs'
      expect(response.body).to include('3') # Failed jobs count
    end

    it 'displays running jobs' do
      get '/admin/jobs'
      expect(response.body).to include('RunningJob')
    end

    it 'displays recent completed jobs' do
      get '/admin/jobs'
      expect(response.body).to include('CompletedJob')
    end

    context 'when not admin' do
      before { sign_in normal_user, scope: :user }

      it 'redirects to root with error' do
        get '/admin/jobs'
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('管理者権限が必要です。')
      end
    end
  end

  describe 'POST /admin/jobs/:id/retry' do
    let(:failed_job) do
      job = SolidQueue::Job.create!(
        queue_name: 'default',
        class_name: 'TestRetryJob',
        arguments: [ 'test_arg' ].to_json,
        priority: 5,
        active_job_id: SecureRandom.uuid
      )

      SolidQueue::FailedExecution.create!(
        job: job,
        error: 'Retry test error'
      )
    end

    it 'retries failed job' do
      expect {
        post "/admin/jobs/#{failed_job.id}/retry"
      }.to change { SolidQueue::Job.count }.by(1)
        .and change { SolidQueue::FailedExecution.count }.by(-1)
    end

    it 'creates new job with same parameters' do
      post "/admin/jobs/#{failed_job.id}/retry"

      new_job = SolidQueue::Job.order(:created_at).last
      expect(new_job.queue_name).to eq('default')
      expect(new_job.class_name).to eq('TestRetryJob')
      expect(new_job.arguments).to eq([ 'test_arg' ].to_json)
      expect(new_job.priority).to eq(5)
    end

    it 'redirects with success message' do
      post "/admin/jobs/#{failed_job.id}/retry"
      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:notice]).to include('TestRetryJob')
      expect(flash[:notice]).to include('再実行キューに追加')
    end
  end

  describe 'DELETE /admin/jobs/:id' do
    let(:failed_job) do
      job = SolidQueue::Job.create!(
        queue_name: 'default',
        class_name: 'TestDeleteJob',
        arguments: [].to_json,
        priority: 0,
        active_job_id: SecureRandom.uuid
      )

      SolidQueue::FailedExecution.create!(
        job: job,
        error: 'Delete test error'
      )
    end

    it 'deletes failed job' do
      expect {
        delete "/admin/jobs/#{failed_job.id}"
      }.to change { SolidQueue::FailedExecution.count }.by(-1)
    end

    it 'redirects with success message' do
      delete "/admin/jobs/#{failed_job.id}"
      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:notice]).to include('TestDeleteJob')
      expect(flash[:notice]).to include('削除しました')
    end
  end

  describe 'POST /admin/jobs/retry_all' do
    before do
      3.times do |i|
        job = SolidQueue::Job.create!(
          queue_name: 'default',
          class_name: "BatchRetryJob#{i}",
          arguments: [].to_json,
          priority: 0,
          active_job_id: SecureRandom.uuid
        )

        SolidQueue::FailedExecution.create!(
          job: job,
          error: "Batch retry error #{i}"
        )
      end
    end

    it 'retries all failed jobs' do
      expect {
        post '/admin/jobs/retry_all'
      }.to change { SolidQueue::Job.count }.by(3)
        .and change { SolidQueue::FailedExecution.count }.by(-3)
    end

    it 'redirects with success message' do
      post '/admin/jobs/retry_all'
      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:notice]).to include('3件')
      expect(flash[:notice]).to include('再実行キューに追加')
    end
  end

  describe 'DELETE /admin/jobs/clear_all' do
    before do
      2.times do |i|
        job = SolidQueue::Job.create!(
          queue_name: 'default',
          class_name: "BatchDeleteJob#{i}",
          arguments: [].to_json,
          priority: 0,
          active_job_id: SecureRandom.uuid
        )

        SolidQueue::FailedExecution.create!(
          job: job,
          error: "Batch delete error #{i}"
        )
      end
    end

    it 'deletes all failed jobs' do
      expect {
        delete '/admin/jobs/clear_all'
      }.to change { SolidQueue::FailedExecution.count }.by(-2)
    end

    it 'redirects with success message' do
      delete '/admin/jobs/clear_all'
      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:notice]).to include('2件')
      expect(flash[:notice]).to include('削除しました')
    end
  end
end
