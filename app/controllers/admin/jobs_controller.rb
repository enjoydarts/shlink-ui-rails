class Admin::JobsController < Admin::AdminController
  def index
    @failed_jobs = SolidQueue::FailedExecution.includes(:job)
                                              .order(created_at: :desc)
                                              .page(params[:page])
                                              .per(20)

    @running_jobs = SolidQueue::Job.where(finished_at: nil)
                                   .order(created_at: :desc)
                                   .limit(10)

    @recent_jobs = SolidQueue::Job.where.not(finished_at: nil)
                                  .order(finished_at: :desc)
                                  .limit(10)
  end

  def retry
    failed_execution = SolidQueue::FailedExecution.find(params[:id])
    job = failed_execution.job

    # 元のジョブの情報を使って新しいジョブを作成
    retry_job = SolidQueue::Job.create!(
      queue_name: job.queue_name,
      class_name: job.class_name,
      arguments: job.arguments,
      priority: job.priority,
      active_job_id: SecureRandom.uuid
    )

    # 失敗レコードを削除
    failed_execution.destroy!

    redirect_to admin_jobs_path, notice: "ジョブ「#{job.class_name}」を再実行キューに追加しました。"
  rescue StandardError => e
    redirect_to admin_jobs_path, alert: "ジョブの再実行に失敗しました: #{e.message}"
  end

  def retry_all
    failed_count = 0

    SolidQueue::FailedExecution.find_each do |failed_execution|
      job = failed_execution.job

      SolidQueue::Job.create!(
        queue_name: job.queue_name,
        class_name: job.class_name,
        arguments: job.arguments,
        priority: job.priority,
        active_job_id: SecureRandom.uuid
      )

      failed_execution.destroy!
      failed_count += 1
    end

    redirect_to admin_jobs_path, notice: "#{failed_count}件の失敗ジョブを再実行キューに追加しました。"
  rescue StandardError => e
    redirect_to admin_jobs_path, alert: "一括再実行に失敗しました: #{e.message}"
  end

  def destroy
    failed_execution = SolidQueue::FailedExecution.find(params[:id])
    job_name = failed_execution.job.class_name

    failed_execution.destroy!

    redirect_to admin_jobs_path, notice: "失敗ジョブ「#{job_name}」を削除しました。"
  rescue StandardError => e
    redirect_to admin_jobs_path, alert: "ジョブの削除に失敗しました: #{e.message}"
  end

  def clear_all
    count = SolidQueue::FailedExecution.count
    SolidQueue::FailedExecution.delete_all

    redirect_to admin_jobs_path, notice: "#{count}件の失敗ジョブをすべて削除しました。"
  rescue StandardError => e
    redirect_to admin_jobs_path, alert: "一括削除に失敗しました: #{e.message}"
  end
end
