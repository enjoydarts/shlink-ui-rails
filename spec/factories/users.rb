FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password123!" }
    password_confirmation { "Password123!" }
    role { "normal_user" }
    confirmed_at { Time.current }

    trait :admin do
      role { "admin" }
    end

    trait :from_oauth do
      provider { "google_oauth2" }
      sequence(:uid) { |n| "google_uid_#{n}" }
      name { "OAuth User" }
    end

    trait :from_omniauth do
      provider { "google_oauth2" }
      sequence(:uid) { |n| "google_uid_#{n}" }
      name { "OAuth User" }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
