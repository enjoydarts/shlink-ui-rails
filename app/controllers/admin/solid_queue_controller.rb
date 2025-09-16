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

  def pause_all
    redirect_to admin_solid_queue_index_path, alert: "一時停止機能は現在利用できません。"
  end

  def resume_all
    redirect_to admin_solid_queue_index_path, alert: "再開機能は現在利用できません。"
  end

  def clear_finished
    service = SolidQueueDashboardService.new
    count = service.clear_finished_jobs
    redirect_to admin_solid_queue_index_path, notice: "完了済みジョブ #{count} 件を削除しました。"
  end
end
