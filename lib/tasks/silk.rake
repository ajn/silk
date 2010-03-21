FILES_ROOT = "#{RAILS_ROOT}/vendor/plugins/silk/files"

require "#{RAILS_ROOT}/vendor/plugins/silk/lib/rake_helpers"

namespace :silk do
  
  namespace :install do
    
    desc "Install Silk into a freshly created Rails project"
    task :fresh => :environment do

      puts "\n\n"
      puts "--------------------"
      puts "| Welcome to Silk! |"
      puts "--------------------"
      puts "\n\n"

      if fresh_install? || confirm("Warning: Existing silk tables found! Type yes to re-install, overwriting files AND database tables:")
        
        puts "Attempting to install Silk into a freshly created Rails project...\n\n"
        
        install_step "Checking Rails version", "Sorry. Silk requires Rails 2.3.5 for now!" do
          raise unless Rails.version == '2.3.5'
        end
      
        install_step "Removing default Rails index.html file", "SKIP (File not present)" do
          FileUtils.remove "#{RAILS_ROOT}/public/index.html"
        end

        install_step "Removing default Rails logo from images", "SKIP (File already deleted)" do
          FileUtils.remove "#{RAILS_ROOT}/public/images/rails.png"
        end

        install_step "Copy over default application layout" do
          FileUtils.cp "#{FILES_ROOT}/layouts/application.html.erb", "#{RAILS_ROOT}/app/views/layouts/application.html.erb"
        end
      
        install_step "Include SilkHelper within application helper" do
          FileUtils.cp "#{FILES_ROOT}/helpers/application_helper.rb", "#{RAILS_ROOT}/app/helpers/application_helper.rb"
        end
      
        install_step "Copy over default CSS files" do
          FileUtils.cp "#{FILES_ROOT}/stylesheets/reset.css",  "#{RAILS_ROOT}/public/stylesheets/reset.css"
          FileUtils.cp "#{FILES_ROOT}/stylesheets/layout.css",  "#{RAILS_ROOT}/public/stylesheets/layout.css"
          FileUtils.cp "#{FILES_ROOT}/stylesheets/content.css", "#{RAILS_ROOT}/public/stylesheets/content.css"
        end
      
        install_step "Overwrite default Rails routes.rb with Silk routes" do
          FileUtils.cp "#{FILES_ROOT}/routes/routes.rb", "#{RAILS_ROOT}/config/routes.rb"
        end

        install_step "Installing Silk preferences file to /config/silk.yml" do
          FileUtils.cp "#{FILES_ROOT}/config/silk.yml", "#{RAILS_ROOT}/config/silk.yml"
        end

        install_step "Adding Silk tables to DB" do
          #exec "DROP TABLE silk_pages; DROP TABLE silk_content"
          ['Sessions','Users','Content','Pages'].each do |migration|
            require "#{RAILS_ROOT}/vendor/plugins/silk/db/migrate/create_silk_#{migration.underscore}.rb"
            "CreateSilk#{migration}".constantize.up
          end
        end
    
        install_step "Creating default Home Page in database" do
          page = Silk::Page.new(:path => '/', :title => 'Home Page')
          page.save!
          page.cached_content.body = File.read "#{FILES_ROOT}/welcome_screen/welcome.html.erb"
          page.save!
        end
    
        install_step "Setup Admin user" do
          Silk::User.create(:login => 'admin', :password => 'password', :password_confirmation => 'password')
        end  
  
        puts "------------------------------------------"
        puts "| Congratulations! Silk is now installed |"
        puts "------------------------------------------"
        puts "\n"
        puts "  Login with:\n\n"
        puts "  Username: admin"
        puts "  Password: password"
        puts "\n"
        puts "------------------------------------------"
        puts "\n"
      end
    
    end
    
    desc "Install files for Recommended Hosting Environment"
    task :hosting => :environment do
      
      install_step "Installing default .gitignore file" do
        FileUtils.cp "#{FILES_ROOT}/other/gitignore", "#{RAILS_ROOT}/.gitignore"
      end

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