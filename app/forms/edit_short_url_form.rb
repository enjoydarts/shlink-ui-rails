class EditShortUrlForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :short_code, :string
  attribute :title, :string
  attribute :long_url, :string
  attribute :valid_until, :datetime
  attribute :max_visits, :string
  attribute :tags, :string
  attribute :custom_slug, :string

  validates :short_code, presence: true
  validates :long_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  validates :valid_until, comparison: { greater_than: -> { Time.current } }, allow_blank: true
  validate :validate_max_visits_format
  validate :validate_tags_format
  validate :validate_custom_slug_format

  # 既存の ShortUrl モデルから初期化
  def self.from_short_url(short_url)
    new(
      short_code: short_url.short_code,
      title: short_url.title,
      long_url: short_url.long_url,
      valid_until: short_url.valid_until,
      max_visits: short_url.max_visits&.to_s,
      tags: short_url.tags_array.join(", "),
      custom_slug: short_url.short_code
    )
  end

  # タグを配列に変換するメソッド
  def tags_array
    return [] if tags.blank?

    tags.split(",").map(&:strip).reject(&:blank?).uniq
  end

  # 有効期限をクリアするためのヘルパー
  def clear_valid_until
    self.valid_until = ""
  end

  # 訪問制限をクリアするためのヘルパー
  def clear_max_visits
    self.max_visits = ""
  end

  # 更新用のパラメータを取得
  def update_params
    params = {}
    params[:title] = title if title.present?
    params[:long_url] = long_url if long_url.present?

    # タグの処理
    if tags.present?
      params[:tags] = tags_array if tags_array.any?
    elsif tags == ""
      # 空文字の場合はnullを送信してタグをクリア
      params[:tags] = nil
    end

    # 有効期限の処理
    if valid_until.present?
      params[:valid_until] = valid_until
    elsif valid_until == ""
      # 空文字の場合はnullを送信して値をクリア
      params[:valid_until] = nil
    end

    # 訪問制限の処理
    if max_visits.present?
      params[:max_visits] = max_visits.to_i
    elsif max_visits == ""
      # 空文字の場合はnullを送信して値をクリア
      params[:max_visits] = nil
    end

    # カスタムスラッグの処理（元のshort_codeと同じ場合は除外）
    params[:custom_slug] = custom_slug if custom_slug.present? && custom_slug != short_code

    params
  end

  private

  def validate_max_visits_format
    return if max_visits.blank?

    # 数値でない場合
    unless max_visits.to_s.match?(/\A\d+\z/)
      errors.add(:max_visits, "訪問制限は正の整数で入力してください")
      return
    end

    # 正の整数でない場合
    visits = max_visits.to_i
    if visits <= 0
      errors.add(:max_visits, "訪問制限は1以上の整数で入力してください")
    end
  end

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

  def validate_custom_slug_format
    return if custom_slug.blank?

    # カスタムスラッグの形式チェック（英数字、ハイフン、アンダースコアのみ）
    unless custom_slug.match?(/\A[a-zA-Z0-9_-]+\z/)
      errors.add(:custom_slug, "カスタムスラッグは英数字、ハイフン、アンダースコアのみ使用できます")
    end

    # 長さ制限 (3-50文字)
    if custom_slug.length < 3 || custom_slug.length > 50
      errors.add(:custom_slug, "カスタムスラッグは3文字以上50文字以内で入力してください")
    end
  end
end
