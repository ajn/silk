class Silk::Preference
  
  cattr_accessor :silk_preferences
  
  def self.preferences
    @@silk_preferences ||= YAML.load(load_from_file)
  rescue
    raise 'Unable to load Silk preferences file in RAILS_ROOT/config/silk.yml. Please check syntax is valid YAML.'
  end
  
  def self.load_from_file
    File.read("#{RAILS_ROOT}/config/silk.yml")
  end
  
  def self.get(key)
    preferences[key.to_s]
  end
  
end
