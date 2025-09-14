class Admin::UsersController < Admin::AdminController
  before_action :set_user, only: [ :show, :update, :destroy ]

  def index
    @users = User.order(:created_at)
                 .page(params[:page])
                 .per(20)

    # 検索・フィルタリング
    @users = filter_users(@users) if params[:search].present? || params[:role].present?

    # 総アクセス数を事前計算
    user_ids = @users.map(&:id)
    @user_visit_counts = ShortUrl.where(user_id: user_ids)
                                 .group(:user_id)
                                 .sum(:visit_count)

    @total_users = User.count
    @admin_users = User.where(role: "admin").count
    @normal_users = User.where(role: "normal_user").count
  end

  def show
    @user_stats = Admin::UserManagementService.new(@user).user_statistics
    @recent_short_urls = @user.recent_short_urls(10)
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "ユーザー情報を更新しました。"
    else
      @user_stats = Admin::UserManagementService.new(@user).user_statistics
      @recent_short_urls = @user.recent_short_urls(10)
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "自分自身のアカウントは削除できません。"
      return
    end

    @user.destroy!
    redirect_to admin_users_path, notice: "ユーザーを削除しました。"
  rescue StandardError => e
    redirect_to admin_users_path, alert: "ユーザーの削除に失敗しました: #{e.message}"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    # 権限昇格対策：roleパラメータは明示的にスーパー管理者のみ変更可能
    permitted_params = {}

    # 基本パラメータの安全な抽出（空値も含める）
    permitted_params[:name] = params[:user][:name] if params[:user].key?(:name)
    permitted_params[:email] = params[:user][:email] if params[:user].key?(:email)

    # 管理者のみroleパラメータを追加で許可
    if current_user&.admin? && params[:user][:role].present?
      permitted_params[:role] = params[:user][:role]
    end

    # ActionController::Parametersオブジェクトを返す
    ActionController::Parameters.new(permitted_params).permit!
  end

  def filter_users(users)
    users = users.where("name LIKE ? OR email LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    users = users.where(role: params[:role]) if params[:role].present?
    users
  end
end
