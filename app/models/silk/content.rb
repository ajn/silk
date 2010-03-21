#  Content is at the heart of Silk. Content can either be normal editable content, re-usable snippet content, or page content
#
#  When path = nil      Snippet. Can be included on any page using the helper. E.g. <%= snippet 'Footer' %>
#  When name = nil      Page content. This is the main page body content
#  When content = nil   New content. The nil value for content automatically triggers the Edit Page dialog

class Silk::Content < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  
  set_table_name :silk_content
  before_validation :strip_whitespace!
  before_validation :ensure_default_content_type_set!
  
  class << self
  
    def process(path, name, initial_content, options = {})
      new(:path => (options[:snippet] ? nil : path), :name => name, :body => initial_content).find_or_create
    end
  
    def all_for_path(path)
      find_all_by_path(path).index_by(&:name)
    end
    
    def allowed_types
      @@silk_allowed_types ||= sanitized_allowed_types
    end
  
    def default_type
      content_type = Silk::Preference.get(:default_content_type)
      allowed?(content_type) ? content_type.to_s : 'html'
    end
  
    def valid_type_or_default(content_type)
      allowed?(content_type) ? content_type.to_s : default_type
    end

    def allowed?(content_type)
      allowed_types.keys.include?(content_type)
    end

    def supported_content_types
      standard = ['plain', 'html', 'erb']
      returning standard do |result|
        result.push 'haml' if defined?(Haml) # Support HAML if installed
      end.sort
    end

    def sanitized_allowed_types
      Silk::Preference.get(:allowed_content_types).map do |content_type|
        next unless supported_content_types.include? content_type['type']
        content_type['label'] = content_type['type'].titleize unless content_type['label']
        content_type
      end.compact.index_by{|x| x['type'] }
    end
  
  end


  def find_or_create
    load_from_db || create_new
  end
  
  def snippet?
    path.nil?
  end
  
  def page_content?
    name.nil?
  end
  
  def content_type
    self.class.valid_type_or_default(read_attribute(:content_type))
  end
  
  # Forces content_type to call method rather than use variable. Affects attributes.to_json used by silk.js
  def attributes
    super.merge(:content_type => content_type)
  end
  
  def render
    case content_type
      when 'erb'
        ERB.new(body.to_s).result
      when 'haml'
        base = ActionView::Base.new('/app/views/content', {}, Silk::ContentController)
        Haml::Engine.new(body.to_s).render(base)
      when 'plain'
        simple_format(body.to_s)
      else
        body.to_s
    end
  end
  
  
  private
  
    def load_from_db
      self.class.find_by_path_and_name(path, name)
    end
    
    def create_new
      save; reload; self
    end

    def strip_whitespace!
      self.body = body.strip if body.present?
    end
    
    def ensure_default_content_type_set!
      self.content_type = content_type
    end
      
end
