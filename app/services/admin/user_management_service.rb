class Admin::UserManagementService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def user_statistics
    {
      basic_info: user_basic_info,
      activity: user_activity_stats,
      short_urls: user_short_url_stats,
      security: user_security_stats
    }
  end

  private

  def user_basic_info
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      provider: user.provider,
      created_at: user.created_at,
      confirmed_at: user.confirmed_at,
      confirmed: user.confirmed?,
      locked: user_locked?
    }
  end

  def user_activity_stats
    {
      sign_in_count: user.sign_in_count,
      current_sign_in_at: user.current_sign_in_at,
      last_sign_in_at: user.last_sign_in_at,
      current_sign_in_ip: user.current_sign_in_ip,
      last_sign_in_ip: user.last_sign_in_ip,
      days_since_last_login: days_since_last_login,
      login_frequency: login_frequency
    }
  end

  def user_short_url_stats
    {
      total_short_urls: user.short_urls.count,
      total_visits: user.short_urls.sum(:visit_count),
      created_this_month: user.short_urls.where("created_at >= ?", 1.month.ago).count,
      created_this_week: user.short_urls.where("created_at >= ?", 1.week.ago).count,
      most_popular_url: most_popular_user_url,
      recent_urls: recent_user_urls,
      tags_used: tags_used_by_user
    }
  end

  def user_security_stats
    {
      two_factor_enabled: user.two_factor_enabled?,
      totp_enabled: user.totp_enabled?,
      webauthn_enabled: user.webauthn_enabled?,
      webauthn_credentials_count: user.webauthn_credentials.count,
      failed_attempts: user.failed_attempts || 0,
      last_failed_attempt: last_failed_attempt_info,
      password_changed: password_last_changed,
      oauth_user: user.from_omniauth?
    }
  end

  def user_locked?
    user.respond_to?(:locked_at) && user.locked_at.present?
  end

  def days_since_last_login
    return nil unless user.last_sign_in_at

    (Date.current - user.last_sign_in_at.to_date).to_i
  end

  def login_frequency
    return "なし" if user.sign_in_count.zero? || user.created_at.nil?

    days_since_registration = (Date.current - user.created_at.to_date).to_i
    days_since_registration = 1 if days_since_registration.zero?

    frequency = user.sign_in_count.to_f / days_since_registration

    case frequency
    when 0..0.1
      "低"
    when 0.1..0.5
      "普通"
    else
      "高"
    end
  end

  def most_popular_user_url
    popular_url = user.short_urls.order(visit_count: :desc).first
    return nil unless popular_url

    {
      short_code: popular_url.short_code,
      short_url: popular_url.short_url,
      long_url: truncate_url(popular_url.long_url),
      visit_count: popular_url.visit_count,
      created_at: popular_url.created_at
    }
  end

  def recent_user_urls(limit = 5)
    user.short_urls
        .order(created_at: :desc)
        .limit(limit)
        .map do |short_url|
          {
            short_code: short_url.short_code,
            short_url: short_url.short_url,
            long_url: truncate_url(short_url.long_url),
            visit_count: short_url.visit_count,
            created_at: short_url.created_at
          }
        end
  end

  def tags_used_by_user
    user.short_urls
        .where.not(tags: [ nil, "" ])
        .pluck(:tags)
        .map { |tags_json| JSON.parse(tags_json) rescue [] }
        .flatten
        .uniq
        .sort
  rescue StandardError
    []
  end

  def last_failed_attempt_info
    # Deviseのfailed_attemptsに関する情報
    # 実際の失敗ログがある場合はそれを取得
    return nil if user.failed_attempts.zero?

    {
      count: user.failed_attempts,
      last_attempt_ip: user.current_sign_in_ip, # 近似値
      locked: user_locked?
    }
  end

  def password_last_changed
    # パスワード変更履歴がある場合の情報
    # Deviseのreset_password_sent_atを使用（近似値）
    return nil unless user.reset_password_sent_at

    {
      changed_at: user.reset_password_sent_at,
      days_ago: (Date.current - user.reset_password_sent_at.to_date).to_i
    }
  end

  def truncate_url(url, length = 50)
    return url if url.length <= length

    "#{url[0..length - 4]}..."
  end

  # クラスメソッド群

  def self.user_activity_summary
    {
      active_today: User.where("current_sign_in_at >= ?", 24.hours.ago).count,
      active_this_week: User.where("current_sign_in_at >= ?", 1.week.ago).count,
      active_this_month: User.where("current_sign_in_at >= ?", 1.month.ago).count,
      inactive_users: User.where("current_sign_in_at < ? OR current_sign_in_at IS NULL", 30.days.ago).count,
      never_logged_in: User.where(sign_in_count: 0).count
    }
  end

  def self.top_users_by_urls(limit = 10)
    User.joins(:short_urls)
        .group("users.id", "users.name", "users.email")
        .order("COUNT(short_urls.id) DESC")
        .limit(limit)
        .pluck("users.id", "users.name", "users.email", "COUNT(short_urls.id) as url_count")
        .map do |id, name, email, count|
          {
            id: id,
            name: name || email.split("@").first,
            email: email,
            short_url_count: count
          }
        end
  end

  def self.top_users_by_visits(limit = 10)
    User.joins(:short_urls)
        .group("users.id", "users.name", "users.email")
        .order("SUM(short_urls.visit_count) DESC")
        .limit(limit)
        .pluck("users.id", "users.name", "users.email", "SUM(short_urls.visit_count) as total_visits")
        .map do |id, name, email, visits|
          {
            id: id,
            name: name || email.split("@").first,
            email: email,
            total_visits: visits
          }
        end
  end
end
