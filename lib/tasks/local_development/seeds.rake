if Rails.env.development?
  Rake::Task["db:seed"].enhance([ "db:local:seed" ])

  namespace :db do
    namespace :local do
      desc "Seed Data"
      task seed: :environment do
        raise "Refusing to seed in #{Rails.env}. This task is only meant for the local development environment." unless Rails.env.development?

        Order.destroy_all
        Prescription.destroy_all
        User.destroy_all

        FactoryBot.create_list(:user, 20).each do |user|
          FactoryBot.create_list(:prescription, rand(3), :random_status).each do |prescription|
            rand(5).times { FactoryBot.create(:order, :random_status, prescription: prescription, buyer: user) }
          end
        end

        puts "Seeded #{User.all.size} users"
        puts "Seeded #{Prescription.all.size} prescriptions"
        puts "Seeded #{Order.all.size} orders"
      end
    end
  end
end
