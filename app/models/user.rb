class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :omniauthable, omniauth_providers: [:google_oauth2]

  # User roles
  enum :role, {
    normal_user: "normal_user",
    admin: "admin"
  }, default: :normal_user

  validates :name, presence: true, if: :from_omniauth?
  validates :role, inclusion: { in: roles.keys }

  # OAuth methods
  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
    end
  end

  def from_omniauth?
    provider.present? && uid.present?
  end

  def display_name
    name.presence || email.split("@").first
  end
end
