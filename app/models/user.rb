class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable, :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # User roles
  enum :role, {
    normal_user: "normal_user",
    admin: "admin"
  }, default: :normal_user

  validates :name, presence: true, if: :from_omniauth?
  validates :role, inclusion: { in: roles.keys }

  # OAuth methods
  def self.from_omniauth(auth)
    user = where(email: auth.info.email).first_or_initialize do |u|
      u.email = auth.info.email
      u.password = Devise.friendly_token[0, 20]
      u.password_confirmation = u.password
      u.name = auth.info.name
      u.provider = auth.provider
      u.uid = auth.uid
    end

    if user.new_record?
      user.skip_confirmation!
      user.save!
    end

    user
  end

  def from_omniauth?
    provider.present? && uid.present?
  end

  def display_name
    name.presence || email.split("@").first
  end

  # Association with short URLs
  has_many :short_urls, dependent: :destroy

  # Get user's short URLs ordered by creation date
  def recent_short_urls(limit = nil)
    scope = short_urls.recent
    limit ? scope.limit(limit) : scope
  end
end
