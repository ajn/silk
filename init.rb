silk_plugin_assets_path = "#{RAILS_ROOT}/vendor/plugins/silk/public"
silk_public_assets_path = "#{RAILS_ROOT}/public/silk_engine"

# REQUIRE AUTHLOGIC (User authentication library)
require 'authlogic'

# MIRROR PUBLIC FILES
unless RAILS_ENV == 'test'

  begin
  
    if File.exists? silk_public_assets_path
      puts "SILK: Updating public assets directory with latest files..."
      FileUtils.remove_dir silk_public_assets_path
    else
      puts "SILK: Public assets directory does not exist. Creating now..."
    end

    FileUtils.mkdir_p silk_public_assets_path
    
    puts "SILK: Copying public assets to #{silk_public_assets_path}"
    Silk::mirror_files_from silk_plugin_assets_path, silk_public_assets_path
  
    puts "SILK: Silk public assets successfully installed!"
  rescue
    puts "SILK ERROR! Unable to copy over public assets from the plugin. Silk will not work correctly without these files."
    FileUtils.remove_dir silk_public_assets_path
  end

end