class ShortenForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :long_url, :string
  attribute :slug, :string
  attribute :include_qr_code, :boolean, default: false
  attribute :valid_until, :datetime
  attribute :max_visits, :integer
  attribute :tags, :string
  attribute :device_redirects_enabled, :boolean, default: false
  attribute :android_url, :string
  attribute :ios_url, :string
  attribute :desktop_url, :string

  validates :long_url, presence: true, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
  validates :valid_until, comparison: { greater_than: -> { Time.current } }, allow_blank: true
  validates :max_visits, numericality: { greater_than: 0, only_integer: true }, allow_blank: true
  validates :android_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  validates :ios_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  validates :desktop_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  validate :validate_tags_format
  validate :validate_device_redirects

  # タグを配列に変換するメソッド
  def tags_array
    return [] if tags.blank?

    tags.split(",").map(&:strip).reject(&:blank?).uniq
  end

  # デバイス別リダイレクトルールを生成するメソッド
  def device_redirect_rules
    return [] unless device_redirects_enabled

    rules = []

    if android_url.present?
      rules << {
        longUrl: android_url,
        conditions: [
          { type: "device", matchValue: "android", matchKey: nil }
        ]
      }
    end

    if ios_url.present?
      rules << {
        longUrl: ios_url,
        conditions: [
          { type: "device", matchValue: "iOS", matchKey: nil }
        ]
      }
    end

    if desktop_url.present?
      rules << {
        longUrl: desktop_url,
        conditions: [
          { type: "device", matchValue: "desktop", matchKey: nil }
        ]
      }
    end

    rules
  end

  private

  def validate_tags_format
    return if tags.blank?

    tag_array = tags_array

    # タグの数制限 (最大10個)
    if tag_array.length > 10
      errors.add(:tags, "タグは最大10個まで設定できます")
    end

    # 個々のタグの長さ制限 (最大20文字)
    tag_array.each do |tag|
      if tag.length > 20
        errors.add(:tags, "各タグは20文字以内で入力してください")
        break
      end
    end
  end

  def validate_device_redirects
    return unless device_redirects_enabled

    device_urls = [ android_url, ios_url, desktop_url ].filter_map(&:presence)

    if device_urls.empty?
      errors.add(:base, "デバイス別リダイレクトを有効にする場合は、少なくとも1つのデバイス用URLを設定してください")
    end
  end
end
