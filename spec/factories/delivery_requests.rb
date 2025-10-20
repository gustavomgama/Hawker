FactoryBot.define do
  factory :delivery_request, class: Hash do
    skip_create

    sequence(:id) { |n| "request-#{n}" }
    name { "John Doe" }
    address { "Rua Example, 123" }
    lat { -23.5505 }
    long { -46.6333 }
    status { "pending" }
    requested_at { Time.current }

    trait :accepted do
      status { "accepted" }
      accepted_at { Time.current }
    end

    trait :completed do
      status { "completed" }
      accepted_at { 30.minutes.ago }
      completed_at { Time.current }
    end

    initialize_with { attributes.stringify_keys }
  end
end
