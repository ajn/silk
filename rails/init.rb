require File.expand_path(File.dirname(__FILE__) + '/../lib/silk.rb')

# MIRROR PUBLIC FILES
Silk::Install.silk_engine if Rails.env.development?

# LOAD SILK APPS
begin
  puts "SILK: Looking for Silk Apps..."
  Silk::App.load_all
rescue
  puts "SILK ERROR! Unable to load Silk Apps"
end
