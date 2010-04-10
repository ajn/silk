module Silk
  module Install
    class << self
      
      # Many thanks to the guys at Rails Engines for this great method
      def mirror_files_from(source, destination)
        return unless File.directory?(source)

        # TODO: use Rake::FileList#pathmap?    
        source_files = Dir[source + "/**/*"]
        source_dirs = source_files.select { |d| File.directory?(d) }
        source_files -= source_dirs

        unless source_files.empty?
          base_target_dir = File.join(destination, File.dirname(source_files.first).gsub(source, ''))
          FileUtils.mkdir_p(base_target_dir)
        end

        source_dirs.each do |dir|
          # strip down these paths so we have simple, relative paths we can
          # add to the destination
          target_dir = File.join(destination, dir.gsub(source, ''))
          begin        
            FileUtils.mkdir_p(target_dir)
          rescue Exception => e
            raise "Could not create directory #{target_dir}: \n" + e
          end
        end

        source_files.each do |file|
          begin
            target = File.join(destination, file.gsub(source, ''))
            unless File.exist?(target) && FileUtils.identical?(file, target)
              FileUtils.cp(file, target)
            end 
          rescue Exception => e
            raise "Could not copy #{file} to #{target}: \n" + e 
          end
        end

      end
      
      def silk_engine
        engine_path = Silk.root('engine')
        public_path = Silk.rails('public/silk-engine')
        begin
          if File.exists? public_path
            puts "Updating SilkEngine with latest files..."
            FileUtils.remove_dir public_path
          else
            puts "Installing silk-engine to #{public_path}"
          end
          
          FileUtils.mkdir_p public_path
          mirror_files_from engine_path, public_path
          puts "silk-engine successfully installed!"
        rescue
          FileUtils.remove_dir public_path
          raise "ERROR! Unable to install silk-engine. Silk will not work correctly without these files."
        end
      end

      def silk_themes
        themes_path = Silk.root('themes')
        public_path = Silk.rails('public/silk-themes')
        copy_text   = "\nPlease manually copy... \nFrom: #{themes_path}\n  To: #{public_path}\n"
        begin
          if File.exists? public_path
            puts "silk-themes is already installed to #{public_path}#{copy_text}If you wish to upgrade."
          else
            puts "Installing silk-themes to #{public_path}"
            FileUtils.mkdir_p public_path
            mirror_files_from themes_path, public_path
            puts "silk-themes successfully installed!"
          end
        rescue
          puts "ERROR! Unable to install silk-themes.#{copy_text}"
        end
      end


      def fresh
        puts "\n\n"
        puts "--------------------"
        puts "| Welcome to Silk! |"
        puts "--------------------"
        puts "\n\n"

        if fresh_install? || confirm("Warning: Existing silk tables found! Type yes to re-install, overwriting files AND database tables:")
          
          puts "Attempting to install Silk into a freshly created Rails project...\n\n"
          
          install_step "Checking Rails version" do
            raise "Sorry. Silk requires Rails 3!" unless Rails::VERSION::MAJOR == 3
          end
          
          install_step "Removing default Rails index.html file", "SIKP (file already removed)" do
            FileUtils.remove Silk.rails('public/index.html')
          end
          
          install_step "Removing default Rails logo from images", "SKIP (file already removed)" do
            FileUtils.remove Silk.rails('public/images/rails.png')
          end
          
          install_step "Copy over default application layout" do
            FileUtils.cp Silk.root('files/layouts/silk.html.erb'), Silk.rails('app/views/layouts/silk.html.erb')
          end
          
          install_step "Installing silk-engine" do
            silk_engine
          end

          install_step "Installing silk-themes" do
            silk_themes
          end
          
          install_step "Installing Silk preferences file to /config/silk.yml" do
            FileUtils.cp Silk.root('files/config/silk.yml'), Silk.rails('config/silk.yml')
          end

          install_step "Installing Silk routes file to /config/initializers/silk_route_set.rb" do
            FileUtils.cp Silk.root('files/initializers/silk_route_set.rb'), Silk.rails('config/initializers/silk_route_set.rb')
          end

          install_step "Installing SilkHelper include file to /config/initializers/silk_application_helper_include.rb" do
            FileUtils.cp Silk.root('files/initializers/silk_application_helper_include.rb'), Silk.rails('config/initializers/silk_application_helper_include.rb')
          end
          
          install_step "Adding Silk tables to DB" do
            ['Sessions','Users','Content','Pages'].each_with_index do |migration, i|
              migration_time = ((Time.now.utc - 5.seconds) + i.seconds).strftime("%Y%m%d%H%M%S")
              migration_file = "#{migration_time}_create_silk_#{migration.underscore}.rb"
              FileUtils.mkdir_p Silk.rails('db/migrate')
              FileUtils.cp Silk.root('db/migrate', "create_silk_#{migration.underscore}.rb"), Silk.rails('db/migrate', migration_file)
              ActiveRecord::Migrator.up(Silk.rails('db/migrate'), migration_time.to_i)
              Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
            end
          end
          
          install_step "Creating default Home Page in database" do
            page = Silk::Page.new(:path => '/', :title => 'Home Page')
            page.save!
            page.cached_content.body = File.read Silk.root('files/welcome_screen/welcome.html.erb')
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
      
      def hosting
        install_step "Installing default .gitignore file" do
          FileUtils.cp Silk.root('other/gitignore'), Silk.rails('/.gitignore')
        end
      end
      
      protected
        
        def install_step(initial_text, error_text = nil, &block)
          begin 
            puts "#{initial_text}..."
            yield
            puts "DONE"
          rescue
            puts error_text || "ERROR! #{$!}"
            exit(1) if error_text.blank?
          ensure
            puts "\n"
          end
        end
        
        def ask(message, default_response = "")
          print "#{message} #{default_response ? '[' + default_response + ']' : ''} "
          response = STDIN.gets.chomp
          response.blank? ? default_response : response
        end
        
        def confirm(message)
          ask(message, default_response = "n") =~ /y|yes/i
        end
        
        def fresh_install?
          !(Silk::Page.table_exists? && Silk::User.table_exists?)
        end
        
    end
  end
end