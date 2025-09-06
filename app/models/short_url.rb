class ShortUrl < ApplicationRecord
  belongs_to :user

  validates :short_code, presence: true, uniqueness: { case_sensitive: false }
  validates :short_url, presence: true
  validates :long_url, presence: true
  validates :visit_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :date_created, presence: true

  scope :recent, -> { order(date_created: :desc) }
  scope :by_user, ->(user) { where(user: user) }

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
end
