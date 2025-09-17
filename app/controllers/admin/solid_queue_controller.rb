class Admin::SolidQueueController < Admin::AdminController
  def index
    service = SolidQueueDashboardService.new
    @stats = service.stats
    @recent_jobs = service.recent_jobs
    @active_processes = service.active_processes

    # エラー判定
    if @stats[:database_error]
      flash.now[:alert] = "Solid Queueテーブルにアクセスできません。データベースマイグレーションが必要な可能性があります。"
    elsif @stats[:active_workers].zero?
      flash.now[:warning] = "Solid Queueワーカーが起動していません。docker-compose.prod.ymlでの起動を確認してください。"
    end
  end

  def workers
    render json: SolidQueueDashboardService.new.worker_processes
  end

  def processes
    render json: SolidQueueDashboardService.new.all_processes
  end

  def failed_jobs
    render json: SolidQueueDashboardService.new.failed_jobs
  end


  def clear_finished
    service = SolidQueueDashboardService.new
    count = service.clear_finished_jobs
    redirect_to admin_solid_queue_index_path, notice: "完了済みジョブ #{count} 件を削除しました。"
  end

  # 個別ジョブ削除
  def destroy
    begin
      failed_execution = SolidQueue::FailedExecution.find(params[:id])
      failed_execution.destroy
      redirect_to admin_solid_queue_index_path, notice: "ジョブを削除しました。"
    rescue => e
      redirect_to admin_solid_queue_index_path, alert: "ジョブの削除に失敗しました: #{e.message}"
    end
  end

  # 個別ジョブ再実行
  def retry
    begin
      failed_execution = SolidQueue::FailedExecution.find(params[:id])
      if failed_execution.job
        failed_execution.job.retry
        failed_execution.destroy
        redirect_to admin_solid_queue_index_path, notice: "ジョブを再実行しました。"
      else
        redirect_to admin_solid_queue_index_path, alert: "ジョブが見つかりません。"
      end
    rescue => e
      redirect_to admin_solid_queue_index_path, alert: "ジョブの再実行に失敗しました: #{e.message}"
    end
  end

  # 全失敗ジョブ再実行
  def retry_all
    begin
      count = 0
      SolidQueue::FailedExecution.includes(:job).find_each do |failed_execution|
        if failed_execution.job
          failed_execution.job.retry
          failed_execution.destroy
          count += 1
        end
      end
      redirect_to admin_solid_queue_index_path, notice: "#{count} 件のジョブを再実行しました。"
    rescue => e
      redirect_to admin_solid_queue_index_path, alert: "ジョブの一括再実行に失敗しました: #{e.message}"
    end
  end

  # 全失敗ジョブ削除
  def clear_all
    begin
      count = SolidQueue::FailedExecution.count
      SolidQueue::FailedExecution.destroy_all
      redirect_to admin_solid_queue_index_path, notice: "#{count} 件の失敗ジョブを削除しました。"
    rescue => e
      redirect_to admin_solid_queue_index_path, alert: "ジョブの一括削除に失敗しました: #{e.message}"
    end
  end
end
