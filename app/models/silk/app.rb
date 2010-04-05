class Silk::App
  
  class << self
    
    def load(app_name)
      app = new(app_name)
      puts "SILK:    Loading #{app.name} (Version #{app.version})"
      app.load!
      app
    end
    
    def directories
      Dir["#{Rails.root}/vendor/plugins/silk_*"]
    end
    
    def list
      directories.map{|dir| dir.split('/').last.downcase.gsub('silk_', '') }
    end
    
    def load_all
      list.each{|app| load(app) }
    end
    
    # Cache as this gets called on every page
    def quick_access_details
      @@qad ||= list.map{|app| load(app).quick_access_details }
    end
    
  end
  
  attr_reader :app_name
  
  def initialize(app_name)
    @app_name = app_name
  end
  
  def load!
    Silk::mirror_files_from "#{app_path}/public/", "#{::SILK_PUBLIC_ASSETS_PATH}/apps/#{app_name}"
  end
  
  def details
    YAML.load(File.open("#{app_path}/details.yml"))
  end
  
  def name
    details['name'] || 'N/A'
  end
  
  def version
    details['version'] || 'N/A'
  end
  
  def description
    details['description'] || 'N/A'
  end
  
  def quick_access_details
    {:app_name => app_name, :name => name, :description => description}
  end
  
  def app_path
    "#{Rails.root}/vendor/plugins/silk_#{app_name}"
  end
  
  def install!
    Dir["#{app_path}/db/migrate/*.rb"].each do |migration|
      require migration
      name = migration.split('/').last.gsub(".rb", '')
      name.classify.constantize.up
    end
  end

end