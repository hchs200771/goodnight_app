namespace :db do
  namespace :migrate do
    desc "Run migrations and annotate models"
    task with_annotate: :environment do
      puts "Running migrations..."
      Rake::Task["db:migrate"].invoke

      puts "Annotating models with bottom position..."
      system("bundle exec annotate --models --position bottom")

      puts "Done!"
    end
  end
end
