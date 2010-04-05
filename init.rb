::SILK_PLUGIN_ASSETS_PATH = "#{Rails.root}/vendor/plugins/silk/public"
::SILK_PUBLIC_ASSETS_PATH = "#{Rails.root}/public/silk_engine"

# MIRROR PUBLIC FILES
unless Rails.env.test?

  begin
    if File.exists? ::SILK_PUBLIC_ASSETS_PATH
      puts "SILK: Updating public assets directory with latest files..."
      FileUtils.remove_dir ::SILK_PUBLIC_ASSETS_PATH
    else
      puts "SILK: Public assets directory does not exist. Creating now..."
    end

    FileUtils.mkdir_p ::SILK_PUBLIC_ASSETS_PATH
    
    puts "SILK: Copying public assets to #{SILK_PUBLIC_ASSETS_PATH}"
    Silk::mirror_files_from  ::SILK_PLUGIN_ASSETS_PATH, ::SILK_PUBLIC_ASSETS_PATH
  
    puts "SILK: Silk public assets successfully installed!"
  rescue
    puts "SILK ERROR! Unable to copy over public assets from the plugin. Silk will not work correctly without these files."
    FileUtils.remove_dir ::SILK_PUBLIC_ASSETS_PATH
  end

end


# LOAD SILK APPS
begin
  puts "SILK: Looking for Silk Apps..."
  Silk::App.load_all
rescue
  puts "SILK ERROR! Unable to load Silk Apps"
end
  




