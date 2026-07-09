FactoryBot.define do
  factory :order do
    association :buyer, factory: :user
    prescription { association :prescription, patient: buyer }
    total_cents { rand(1..prescription.price_cents) }
    status { :pending }
    paid_at { Faker::Time.between_dates(from: 30.days.ago, to: Date.today, period: :all) }

    trait :random_status do
      status { Order.statuses.keys.sample }
    end

    trait :third_party_payer do
      prescription { association :prescription }
    end

    after(:build) do |order|
      if order.processing?  && order.stripe_payment_intent_id.blank?
        order.stripe_payment_intent_id = "pi_#{SecureRandom.alphanumeric(22)}"
      end
    end
  end
end
