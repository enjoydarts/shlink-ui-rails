FactoryBot.define do
  factory :short_url do
    association :user
    sequence(:short_code) { |n| "abc#{n}" }
    sequence(:short_url) { |n| "https://s.test/abc#{n}" }
    long_url { "https://example.com/very/long/url/path" }
    domain { "s.test" }
    title { "Example Page" }
    tags { [ "tag1", "tag2" ].to_json }
    meta { { "description" => "Test URL" }.to_json }
    visit_count { 0 }
    crawlable { true }
    forward_query { true }
    date_created { Time.current }

    trait :with_expiration do
      valid_until { 1.week.from_now }
    end

    trait :with_visit_limit do
      max_visits { 100 }
    end

    trait :expired do
      valid_until { 1.day.ago }
    end

    trait :visit_limit_reached do
      max_visits { 10 }
      visit_count { 10 }
    end

    trait :popular do
      visit_count { 500 }
    end

    trait :without_tags do
      tags { nil }
    end

    trait :without_meta do
      meta { nil }
    end
  end
end
