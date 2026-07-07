if Rails.env.development?
  Rake::Task["db:seed"].enhance([ "db:local:seed" ])

  namespace :db do
    namespace :local do
      desc "Seed Data"
      task seed: :environment do
        raise "Refusing to seed in #{Rails.env}. This task is only meant for the local development environment." unless Rails.env.development?

        User.destroy_all

        FactoryBot.create_list(:user, 20)
        puts "Seeded #{User.all.size} users"
      end
    end
  end
end
