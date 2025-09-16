class Admin::SolidQueueController < Admin::AdminController
  def index
    begin
      @stats = {
        pending_jobs: SolidQueue::Job.joins("LEFT JOIN solid_queue_ready_executions ON solid_queue_ready_executions.job_id = solid_queue_jobs.id")
                                    .where(finished_at: nil)
                                    .where("solid_queue_ready_executions.id IS NOT NULL").count,
        running_jobs: SolidQueue::Job.joins("LEFT JOIN solid_queue_claimed_executions ON solid_queue_claimed_executions.job_id = solid_queue_jobs.id")
                                    .where(finished_at: nil)
                                    .where("solid_queue_claimed_executions.id IS NOT NULL").count,
        finished_jobs: SolidQueue::Job.joins("LEFT JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id")
                                     .where.not(finished_at: nil)
                                     .where("solid_queue_failed_executions.id IS NULL").count,
        failed_jobs: SolidQueue::Job.joins("INNER JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id").count,
        active_workers: SolidQueue::Process.where("last_heartbeat_at > ?", 1.minute.ago).count,
        total_workers: SolidQueue::Process.count
      }

      jobs_data = SolidQueue::Job.select("
          solid_queue_jobs.*,
          CASE
            WHEN solid_queue_jobs.finished_at IS NOT NULL AND solid_queue_failed_executions.id IS NOT NULL THEN 'failed'
            WHEN solid_queue_jobs.finished_at IS NOT NULL THEN 'finished'
            WHEN solid_queue_claimed_executions.id IS NOT NULL THEN 'running'
            WHEN solid_queue_ready_executions.id IS NOT NULL THEN 'pending'
            ELSE 'scheduled'
          END as job_status
        ")
        .joins("LEFT JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id")
        .joins("LEFT JOIN solid_queue_claimed_executions ON solid_queue_claimed_executions.job_id = solid_queue_jobs.id")
        .joins("LEFT JOIN solid_queue_ready_executions ON solid_queue_ready_executions.job_id = solid_queue_jobs.id")
        .order(created_at: :desc)
        .limit(20)

      @recent_jobs = jobs_data.map do |job|
        {
          id: job.id,
          class_name: job.class_name,
          queue_name: job.queue_name,
          created_at: job.created_at,
          finished_at: job.finished_at,
          status: job.job_status
        }
      end
      @active_processes = SolidQueue::Process.includes(:claimed_executions)
                                            .where("last_heartbeat_at > ?", 1.minute.ago)
                                            .order(last_heartbeat_at: :desc)
    rescue ActiveRecord::StatementInvalid => e
      @stats = {
        pending_jobs: 0,
        running_jobs: 0,
        finished_jobs: 0,
        failed_jobs: 0,
        active_workers: 0,
        total_workers: 0
      }
      @recent_jobs = []
      @active_processes = []
      flash.now[:alert] = "Solid Queueテーブルにアクセスできません。データベースマイグレーションが必要な可能性があります。"
    end
  end

  def workers
    @workers = SolidQueue::Process.where("last_heartbeat_at > ?", 1.minute.ago)
                                 .order(:hostname, :pid)
    render json: @workers.map { |worker|
      {
        id: worker.id,
        hostname: worker.hostname,
        pid: worker.pid,
        kind: worker.kind,
        last_heartbeat_at: worker.last_heartbeat_at,
        supervisor_pid: worker.supervisor_pid
      }
    }
  end

  def processes
    @processes = SolidQueue::Process.order(created_at: :desc)
    render json: @processes.map { |process|
      {
        id: process.id,
        hostname: process.hostname,
        pid: process.pid,
        kind: process.kind,
        created_at: process.created_at,
        updated_at: process.updated_at,
        last_heartbeat_at: process.last_heartbeat_at,
        supervisor_pid: process.supervisor_pid
      }
    }
  end

  def failed_jobs
    @failed_jobs = SolidQueue::Job.joins("INNER JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id")
                                  .order(created_at: :desc)
                                  .limit(50)
    render json: @failed_jobs.map { |job|
      {
        id: job.id,
        queue_name: job.queue_name,
        class_name: job.class_name,
        arguments: job.arguments,
        created_at: job.created_at,
        finished_at: job.finished_at
      }
    }
  end

  def pause_all
    # Note: 一時停止機能は実装されていない可能性があります
    redirect_to admin_solid_queue_index_path, alert: "一時停止機能は現在利用できません。"
  end

  def resume_all
    # Note: 再開機能は実装されていない可能性があります
    redirect_to admin_solid_queue_index_path, alert: "再開機能は現在利用できません。"
  end

  def clear_finished
    finished_jobs = SolidQueue::Job.joins("LEFT JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id")
                                  .where.not(finished_at: nil)
                                  .where("solid_queue_failed_executions.id IS NULL")
    count = finished_jobs.count
    finished_jobs.delete_all
    redirect_to admin_solid_queue_index_path, notice: "完了済みジョブ #{count} 件を削除しました。"
  end
end
