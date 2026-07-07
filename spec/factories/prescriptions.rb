FactoryBot.define do
  factory :prescription do
    association :patient, factory: :user
    price_cents { rand(100..50_000) }
    status { :pending_verification }
    medication_name do
      [
        "Amoxicillin", "Lisinopril", "Levothyroxine", "Albuterol",
        "Amlodipine", "Metoprolol", "Omeprazole", "Losartan",
        "Gabapentin", "Hydrochlorothiazide", "Sertraline", "Simvastatin",
        "Montelukast", "Escitalopram", "Rosuvastatin", "Bupropion",
        "Ibuprofen", "Trazodone", "Duloxetine", "Fluoxetine",
        "Pantoprazole", "Pravastatin", "Naproxen", "Fluticasone", "Citalopram"
      ].sample
    end

    trait :random_status do
      status { Prescription.statuses.keys.sample }
    end
  end
end
