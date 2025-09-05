class ShortenForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :long_url, :string
  attribute :slug, :string
  attribute :include_qr_code, :boolean, default: false
  attribute :valid_until, :datetime
  attribute :max_visits, :integer

  validates :long_url, presence: true, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
  validates :valid_until, comparison: { greater_than: -> { Time.current } }, allow_blank: true
  validates :max_visits, numericality: { greater_than: 0, only_integer: true }, allow_blank: true
end
