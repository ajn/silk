require 'authlogic'

module Silk
  class << self
    def root *dirs
      File.expand_path File.join(File.dirname(__FILE__), '..', *dirs.map(&:to_s))
    end
  
    def rails *dirs
      File.join(Rails.root, *dirs.map(&:to_s))
    end

    def lib *modules
      root('lib', *modules)
    end
  end
end

require Silk.lib('silk/routes')
require Silk.lib('silk/install')