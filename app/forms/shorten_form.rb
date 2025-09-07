class ShortenForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :long_url, :string
  attribute :slug, :string
  attribute :include_qr_code, :boolean, default: false
  attribute :valid_until, :datetime
  attribute :max_visits, :integer
  attribute :tags, :string

  validates :long_url, presence: true, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
  validates :valid_until, comparison: { greater_than: -> { Time.current } }, allow_blank: true
  validates :max_visits, numericality: { greater_than: 0, only_integer: true }, allow_blank: true
  validate :validate_tags_format

  # タグを配列に変換するメソッド
  def tags_array
    return [] if tags.blank?

    tags.split(",").map(&:strip).reject(&:blank?).uniq
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
end
