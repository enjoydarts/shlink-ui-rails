class ShortenForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :long_url, :string
  attribute :slug, :string

  validates :long_url, presence: true, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
end
