FactoryBot.define do
  factory :session do
    association :user

    trait :expired do
      created_at { 1.month.ago }
    end
  end
end
