FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }

    trait :with_sessions do
      after(:create) do |user|
        create_list(:session, 2, user: user)
      end
    end
  end
end
