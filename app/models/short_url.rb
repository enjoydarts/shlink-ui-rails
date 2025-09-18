class ShortUrl < ApplicationRecord
  belongs_to :user, counter_cache: true

  validates :short_code, presence: true, uniqueness: { case_sensitive: false }
  validates :short_url, presence: true
  validates :long_url, presence: true
  validates :visit_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :date_created, presence: true

  scope :recent, -> { order(date_created: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  # JSON serialization for tags
  def tags_array
    return [] if tags.blank?

    JSON.parse(tags)
  rescue JSON::ParserError
    []
  end

  def tags_array=(value)
    self.tags = value.to_json
  end

  # JSON serialization for meta
  def meta_hash
    return {} if meta.blank?

    JSON.parse(meta)
  rescue JSON::ParserError
    {}
  end

  def meta_hash=(value)
    self.meta = value.to_json
  end

  # Check if URL has expiration
  def has_expiration?
    valid_until.present?
  end

  # Check if URL is expired
  def expired?
    has_expiration? && valid_until < Time.current
  end

  # Check if URL has visit limit
  def has_visit_limit?
    max_visits.present?
  end

  # Get remaining visits
  def remaining_visits
    return nil unless has_visit_limit?

    [ max_visits - visit_count, 0 ].max
  end

  # Check if URL has reached visit limit
  def visit_limit_reached?
    has_visit_limit? && remaining_visits <= 0
  end

  # Get formatted visit count display
  def visit_display
    if has_visit_limit?
      "#{visit_count}/#{max_visits}"
    else
      visit_count.to_s
    end
  end

  # Check if URL is active (not expired and not reached visit limit)
  def active?
    !expired? && !visit_limit_reached?
  end

  # Soft delete methods
  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end

  def restore!
    update!(deleted_at: nil)
  end

  # JSON serialization for redirect_rules
  def device_redirect_rules
    return [] if redirect_rules.blank?

    JSON.parse(redirect_rules)
  rescue JSON::ParserError
    []
  end

  def device_redirect_rules=(value)
    self.redirect_rules = value.to_json
  end

  # Sync redirect rules from Shlink API
  def sync_redirect_rules_from_api
    begin
      service = Shlink::GetRedirectRulesService.new
      result = service.call(short_code: short_code)

      # GetRedirectRulesService は直接レスポンスボディを返す
      rules = result["redirectRules"] || []
      self.device_redirect_rules = rules
      save! if changed?
      Rails.logger.info "Synced redirect rules for #{short_code}: #{rules.size} rules"
      rules
    rescue Shlink::Error => e
      Rails.logger.warn "Failed to fetch redirect rules for #{short_code}: #{e.message}"
      device_redirect_rules
    rescue => e
      Rails.logger.error "Error syncing redirect rules for #{short_code}: #{e.message}"
      device_redirect_rules
    end
  end

  def android_redirect_url
    rules = device_redirect_rules
    android_rule = rules.find { |rule|
      rule.dig("conditions")&.any? { |c| c["type"] == "device" && c["matchValue"] == "android" }
    }
    android_rule&.dig("longUrl")
  end

  def ios_redirect_url
    rules = device_redirect_rules
    ios_rule = rules.find { |rule|
      rule.dig("conditions")&.any? { |c| c["type"] == "device" && c["matchValue"] == "ios" }
    }
    ios_rule&.dig("longUrl")
  end

  def desktop_redirect_url
    rules = device_redirect_rules
    desktop_rule = rules.find { |rule|
      rule.dig("conditions")&.any? { |c| c["type"] == "device" && c["matchValue"] == "desktop" }
    }
    desktop_rule&.dig("longUrl")
  end
end
