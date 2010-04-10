class Silk::Page < ActiveRecord::Base
  
  set_table_name :silk_pages

  serialize :meta_tags
  
  # The page content is stored as a Silk::Content object uniquely identified by matching path and NIL name
  # We delegate content to cached_content rather than directly to content_source to allow the controller to
  # injecet the page content preloaded by ApplicationController, minimizing calls to the database
  has_one :content,
    :class_name => 'Silk::Content',
    :foreign_key => :path,
    :primary_key => :path,
    :conditions => {:name => nil}
  accepts_nested_attributes_for :content
  delegate :body, :content_type, :to => :cached_content
  attr_writer :cached_content
  
  before_validation :sanitize_layout!
  
  class << self

    def process(path, cached_content)
      returning find_by_path!(path) do |page|
        page.cached_content = cached_content
      end
    end

    def available_layouts
      @available_layouts ||= find_layouts
    end

    def find_layouts
      Dir.entries("#{RAILS_ROOT}/app/views/layouts").map do |x|
        x.to_s.first =~ /[A-Za-z0-9]/ ? x.split('.').first : nil
      end.compact.sort
    end
  
  end


  def layout
    read_attribute(:layout) || 'silk'
  end
  
  def protected?
    path == "/"
  end

  # All calls to page content go through here to allow preloaded content to be injected, savng a call to the DB
  def cached_content
    @cached_content ||= (content || build_content)
  end
  
  # Ensures the content and content_type methods are included when we call attributes.to_json for silk.js
  def attributes
    super.merge(:body => body, :content_type => content_type)
  end
  
  private
  
    def sanitize_layout!
      self.layout = self.class.available_layouts.include?(layout) ? layout : nil
    end

end
