FactoryBot.define do
  factory :user do
    sequence(:email) do |n|
      clean_username = Faker::Internet.unique.username(specifier: 5..10).gsub(/[^a-zA-Z0-9]/, "")
      "#{clean_username}#{n}@example.com"
    end

    sequence(:phone_number) do |n|
      base_number = Faker::Base.numerify("[2-9]##-[2-9]##-####")
      unique_suffix = n.to_s.last(4).rjust(4, "0")
      "#{base_number[0..8]}#{unique_suffix}"
    end
  end
end
