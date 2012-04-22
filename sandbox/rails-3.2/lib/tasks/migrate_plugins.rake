namespace :db do
  desc 'Migrates installed plugins.'
  task :migrate_plugins => :environment do
    Redmine::Plugin.all.each do |plugin|
      plugin.migrate
    end
  end
end
