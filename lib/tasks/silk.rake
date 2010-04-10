namespace :silk do
  
  namespace :install do
    
    desc "Install Silk into a freshly created Rails project"
    task :fresh => :environment do
      Silk::Install.fresh
    end
    
    desc "Install files for Recommended Hosting Environment"
    task :hosting => :environment do
      Silk::Install.hosting
    end    
    
  end
  
  namespace :dev do

    desc_package = "Copy working JS and CSS files to plugin folder for release"
    desc desc_package
    task :package do
      puts "#{desc_package}..."
      FileUtils.cp "#{RAILS_ROOT}/public/silk_engine/javascripts/silk.js",  "#{RAILS_ROOT}/vendor/plugins/silk/public/javascripts/silk.js"
      FileUtils.cp "#{RAILS_ROOT}/public/silk_engine/stylesheets/silk.css", "#{RAILS_ROOT}/vendor/plugins/silk/public/stylesheets/silk.css"
      puts "Done!"
    end
  
  end
  
  namespace :db do
    
    def db_conf
      ActiveRecord::Base.configurations[RAILS_ENV]
    end
    
    desc "Dump entire database contents to /db/dump.sql"
    task :dump => :environment do
      puts "Dumping entire database contents to /db/dump.sql..."
      `mysqldump -u#{db_conf['username']} -p#{db_conf['password']} #{db_conf['database']} > #{RAILS_ROOT}/db/dump.sql`
      puts "Done!"
    end
    
    desc "Restore entire database contents from /db/dump.sql"
    task :restore => :environment do
      puts "Restoring entire database contents from /db/dump.sql..."
      `mysql -u#{db_conf['username']} -p#{db_conf['password']} #{db_conf['database']} < #{RAILS_ROOT}/db/dump.sql`
      puts "Done!"
    end

  end
  
end