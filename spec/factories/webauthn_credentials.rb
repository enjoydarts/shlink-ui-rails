FactoryBot.define do
  factory :webauthn_credential do
    association :user
    sequence(:external_id) { |n| "credential_id_#{n}" }
    public_key { Base64.strict_encode64(SecureRandom.random_bytes(77)) }
    sign_count { 0 }
    sequence(:nickname) { |n| "Test Security Key #{n}" }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_sign_count do
      sign_count { 10 }
    end

    trait :named do |n|
      sequence(:nickname) { |n| "Security Key #{n}" }
    end
  end
end