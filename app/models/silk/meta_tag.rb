class Silk::MetaTag
  
  attr_accessor :type, :body
  
  def self.allowed
    ['keywords','description']
  end
  
end