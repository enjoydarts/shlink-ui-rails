class Admin::SolidQueueController < Admin::AdminController
  def index
    @stats = {
      pending_jobs: SolidQueue::Job.pending.count,
      running_jobs: SolidQueue::Job.running.count,
      finished_jobs: SolidQueue::Job.finished.count,
      failed_jobs: SolidQueue::Job.failed.count,
      active_workers: SolidQueue::Process.active.count,
      total_workers: SolidQueue::Process.count
    }

    @recent_jobs = SolidQueue::Job.includes(:ready_execution)
                                  .order(created_at: :desc)
                                  .limit(20)

    @active_processes = SolidQueue::Process.active
                                          .order(updated_at: :desc)
  end

  def workers
    @workers = SolidQueue::Process.active
                                 .includes(:claimed_executions)
                                 .order(:hostname, :pid)
    render json: @workers.map { |worker|
      {
        id: worker.id,
        hostname: worker.hostname,
        pid: worker.pid,
        kind: worker.kind,
        last_heartbeat_at: worker.last_heartbeat_at,
        supervisor_pid: worker.supervisor_pid,
        claimed_executions: worker.claimed_executions.count
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
    @failed_jobs = SolidQueue::Job.failed
                                  .includes(:failed_execution)
                                  .order(created_at: :desc)
                                  .limit(50)
    render json: @failed_jobs.map { |job|
      {
        id: job.id,
        queue_name: job.queue_name,
        class_name: job.class_name,
        arguments: job.arguments,
        created_at: job.created_at,
        finished_at: job.finished_at,
        error: job.failed_execution&.error
      }
    }
  end

  def pause_all
    SolidQueue::Process.pause_all
    redirect_to admin_solid_queue_index_path, notice: "全てのワーカーを一時停止しました。"
  end

  def resume_all
    SolidQueue::Process.resume_all
    redirect_to admin_solid_queue_index_path, notice: "全てのワーカーを再開しました。"
  end

  def clear_finished
    count = SolidQueue::Job.finished.count
    SolidQueue::Job.finished.delete_all
    redirect_to admin_solid_queue_index_path, notice: "完了済みジョブ #{count} 件を削除しました。"
  end
end