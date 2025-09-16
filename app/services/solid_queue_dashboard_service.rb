class SolidQueueDashboardService
  def self.stats
    new.stats
  end

  def self.recent_jobs(limit = 20)
    new.recent_jobs(limit)
  end

  def self.active_processes
    new.active_processes
  end

  def stats
    {
      pending_jobs: pending_jobs_count,
      running_jobs: running_jobs_count,
      finished_jobs: finished_jobs_count,
      failed_jobs: failed_jobs_count,
      active_workers: active_workers_count,
      total_workers: total_workers_count,
      database_error: false
    }
  rescue ActiveRecord::StatementInvalid, NameError => e
    Rails.logger.error "SolidQueue stats error: #{e.message}"
    empty_stats.merge(database_error: true)
  end

  def recent_jobs(limit = 20)
    jobs_data = SolidQueue::Job.select(job_status_select)
                               .joins(job_execution_joins)
                               .order(created_at: :desc)
                               .limit(limit)

    jobs_data.map { |job| format_job_data(job) }
  rescue ActiveRecord::StatementInvalid
    []
  end

  def active_processes
    SolidQueue::Process.where("last_heartbeat_at > ?", 1.minute.ago)
                      .order(last_heartbeat_at: :desc)
  rescue ActiveRecord::StatementInvalid
    SolidQueue::Process.none
  end

  def clear_finished_jobs
    finished_jobs = SolidQueue::Job.joins("LEFT JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id")
                                  .where.not(finished_at: nil)
                                  .where("solid_queue_failed_executions.id IS NULL")
    count = finished_jobs.count
    finished_jobs.delete_all
    count
  end

  def failed_jobs(limit = 50)
    SolidQueue::Job.joins("INNER JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id")
                   .order(created_at: :desc)
                   .limit(limit)
                   .map { |job| format_failed_job_data(job) }
  end

  def worker_processes
    SolidQueue::Process.where("last_heartbeat_at > ?", 1.minute.ago)
                      .order(:hostname, :pid)
                      .map { |worker| format_worker_data(worker) }
  end

  def all_processes
    SolidQueue::Process.order(created_at: :desc)
                      .map { |process| format_process_data(process) }
  end

  private

  def pending_jobs_count
    SolidQueue::Job.joins("LEFT JOIN solid_queue_ready_executions ON solid_queue_ready_executions.job_id = solid_queue_jobs.id")
                   .where(finished_at: nil)
                   .where("solid_queue_ready_executions.id IS NOT NULL")
                   .count
  end

  def running_jobs_count
    SolidQueue::Job.joins("LEFT JOIN solid_queue_claimed_executions ON solid_queue_claimed_executions.job_id = solid_queue_jobs.id")
                   .where(finished_at: nil)
                   .where("solid_queue_claimed_executions.id IS NOT NULL")
                   .count
  end

  def finished_jobs_count
    SolidQueue::Job.joins("LEFT JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id")
                   .where.not(finished_at: nil)
                   .where("solid_queue_failed_executions.id IS NULL")
                   .count
  end

  def failed_jobs_count
    SolidQueue::Job.joins("INNER JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id")
                   .count
  end

  def active_workers_count
    SolidQueue::Process.where("last_heartbeat_at > ?", 1.minute.ago).count
  end

  def total_workers_count
    SolidQueue::Process.count
  end

  def empty_stats
    {
      pending_jobs: 0,
      running_jobs: 0,
      finished_jobs: 0,
      failed_jobs: 0,
      active_workers: 0,
      total_workers: 0
    }
  end

  def job_status_select
    <<~SQL
      solid_queue_jobs.*,
      CASE
        WHEN solid_queue_jobs.finished_at IS NOT NULL AND solid_queue_failed_executions.id IS NOT NULL THEN 'failed'
        WHEN solid_queue_jobs.finished_at IS NOT NULL THEN 'finished'
        WHEN solid_queue_claimed_executions.id IS NOT NULL THEN 'running'
        WHEN solid_queue_ready_executions.id IS NOT NULL THEN 'pending'
        ELSE 'scheduled'
      END as job_status
    SQL
  end

  def job_execution_joins
    [
      "LEFT JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id",
      "LEFT JOIN solid_queue_claimed_executions ON solid_queue_claimed_executions.job_id = solid_queue_jobs.id",
      "LEFT JOIN solid_queue_ready_executions ON solid_queue_ready_executions.job_id = solid_queue_jobs.id"
    ]
  end

  def format_job_data(job)
    {
      id: job.id,
      class_name: job.class_name,
      queue_name: job.queue_name,
      created_at: job.created_at,
      finished_at: job.finished_at,
      status: job.job_status
    }
  end

  def format_failed_job_data(job)
    {
      id: job.id,
      queue_name: job.queue_name,
      class_name: job.class_name,
      arguments: job.arguments,
      created_at: job.created_at,
      finished_at: job.finished_at
    }
  end

  def format_worker_data(worker)
    {
      id: worker.id,
      hostname: worker.hostname,
      pid: worker.pid,
      kind: worker.kind,
      last_heartbeat_at: worker.last_heartbeat_at,
      supervisor_pid: worker.supervisor_pid
    }
  end

  def format_process_data(process)
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
  end
end
