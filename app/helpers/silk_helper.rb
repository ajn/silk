module SilkHelper

  # Includes essential JS libraries and CSS. The code in here is clearly temporary and needs some major thinking through.
  # A few things to consider... in production mode we should probably get jQuery direct from the Google CDN
  # Note the _silk_page variable is defined deliberately before silk.js is loaded
  def silk_headers
    raw(silk_meta_tags + (silk_load? ? silk_editor_libraries : ''))
  end
  
  # This is a multi-functional Title helper. It can be used to get and set titles
  def title(*attrs)
    @page_title = attrs.first if attrs.first.is_a?(String) and attrs.first.present?
    last = attrs.reverse.first
    @page_title = @page.title if @page && @page.title.present?
    last.is_a?(Symbol) ? content_tag(last, @page_title) : @page_title
  end
  
  # Use within the layout. Wrap inside the <title> tag
  def page_title(options = {})
    [options[:prefix], title, options[:suffix]].compact.join(" #{options[:separator] || ':'} ")
  end
  
  # Yields the page content. Wraps it in a div allowing double-clicking if page is editable. More functionality to come soon.
  def page_content
    silk_editable? ? page_wrapper : raw(@_content_for[:layout])
  end
  
  # Indicates 'normal' editable content should appear, attached to the current page path.
  # If optionally called with a block, the block's content is sucked into the DB and becomes the intial content,
  # saving the designer the need to copy and paste the content into the silk interface each time
  def editable(name, options = {}, &block)
    initial_content = block_given? ? capture(&block) : nil
    content = load_content(name, initial_content, options)
    output = silk_editable? ? content_wrapper(content) : render_content(content)
    block_given? ? concat(output) : output
  end
  
  # Indicates 're-usable' content should appear which can appear on multiple pages.
  # E.g. a page footer. Works exactly like 'editable' otherwise.
  def snippet(name, options = {}, &block)
    output = editable(name, options.merge(:snippet => true), &block)
    block_given? ? '' : output
  end
  
  
  private
  
    # A shortcut to the snippet cache class variable. Can we do this a nicer way?
    def snippet_cache
      controller.class.silk_snippet_cache rescue {}
    end

    # This crucial info gets outputted as a json string and assigned to _silk_data for access by silk.js once it loads
    def silk_data
      { :flash => flash,
        :user => current_user && current_user.login,
        :page => (@page ? @page.attributes : nil),
        :authenticity_token => (form_authenticity_token rescue nil),
        :allowed_content_types => Silk::Content.allowed_types,
        :available_layouts => Silk::Page.available_layouts.map{|x| {:layout => x, :label => x.humanize }},
        :editable_content => {},
        :quick_access_apps => Silk::App.quick_access_details,
        :actions => silk_js_actions,
      }
    end
    
    def silk_meta_tags
      return '' unless @page and @page.meta_tags 
      @page.meta_tags.map{|tag| "<meta name=\"#{tag['name']}\" content=\"#{tag['content']}\"/>\n" }.join('')
    end
    
    def silk_editor_libraries
      @stylesheets = ["libs/smoothness/jquery-ui-1.7.2.custom.css", "core/stylesheets/silk.css"]
      @javascripts = ["libs/jquery-1.3.2.js", "libs/jquery-ui-1.7.2.custom.min.js", "core/javascripts/silk.js"]
      include_silk_app_libraries!
      javascript_tag("_silk_data = #{silk_data.to_json};") +
      stylesheet_link_tag(@stylesheets.map{|x| "/silk_engine/#{x}"}, :cache => 'silk') +
      javascript_include_tag(@javascripts.map{|x| "/silk_engine/#{x}"}, :cache => 'silk')
    end
    
    def include_silk_app_libraries!
      Silk::App.list.each do |app|
        @javascripts << "apps/#{app}/javascripts/silk.app.#{app}.js"
        @stylesheets << "apps/#{app}/stylesheets/silk.app.#{app}.css"
      end
    end
    
    def silk_js_actions
      session[:silk_js_actions] && session.delete(:silk_js_actions) || []
    end
    
    def page_wrapper
      content_tag(:div, raw(@_content_for[:layout]), :ondblclick => 'Silk.page.edit();', :title => 'Double click to edit page')
    end
  
    def load_content(name, initial_content, options)
      # We need to go down two paths here depending on if we have access to the controller (e.g. is it called within a content element)
      return @silk_content[name] if @silk_content and @silk_content[name]
      return snippet_cache[name] if options[:snippet] and snippet_cache[name]
      path = controller.silk_path rescue nil
      returning Silk::Content.process(path, name, initial_content, options) do |content|
        snippet_cache[name] = content if options[:snippet]
      end
    end

    # Wraps all editable content (normal and snippets) when user logged in to allow mouse-over highlighting and other things
    def content_wrapper(content)
      content_tag(:div, render_content(content), :id => "silk-ec-area-id-#{content.id}", :title => "Double click to edit #{content.name}", :class => "silk-editable-content silk-editable-content-#{content.snippet? ? 'snippet' : 'normal'}") +
      javascript_tag("_silk_data['editable_content'][#{content.id}] = $.extend((new silk.editable_content), #{content.attributes.to_json});")
    end
  
    # Catches rendering errors (e.g. invalid HAML or ERB markup) should they occur and displays warning
    def render_content(content)
      raw(content.render)
    rescue
      silk_load? ? content_tag(:div, 'Content Render Error!', :title => $!, :class => 'silk-content-render-error') : ''
    end

end
