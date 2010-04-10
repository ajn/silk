class Silk::BaseController < ApplicationController
  layout 'silk'
    
  before_filter :silk_initialize
  
  # Cache all snippets upon first use (works in production only as class variables do not persist in development)
  # There are obvious implications here to the size of the ruby process. We'll implement a number of ways to deal with this in the future.
  @@silk_snippet_cache = {} unless class_variable_defined?(:@@silk_snippet_cache)
  cattr_accessor :silk_snippet_cache
  
  attr_accessor :silk_content, :silk_path
  helper_method :silk_load?, :silk_editable?, :current_user_session, :current_user
  hide_action :silk_editable?, :silk_load?, :silk_content, :silk_content=, :silk_path, :silk_path=, :silk_snippet_cache, :silk_snippet_cache=
  
  # Included stub here to test silk_initialize
  def index; end
  
  # Is a user logged in and is an editable page present?
  def silk_editable?
    current_user && @page
  end
  
  # Should we load the silk.js and all necessery libraries and CSS?
  def silk_load?
    # Note: sessions must be accessed first before deleting
    session[:silk_load] && session.delete(:silk_load) || silk_editable?
  end
  

  private
  
    # AUTHLOGIC methods - Make authentication more modular in the future
    
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = Silk::UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.user
    end
    
    # END AUTHLOGIC methods

  
    def silk_initialize
      self.silk_path = request.path || request.uri || request.script_name
      self.silk_content = Silk::Content.all_for_path(silk_path)
    end
    
    def silk_js_action(action)
      session[:silk_load] = true
      session[:silk_js_actions] = [] if session[:silk_js_actions].nil?
      session[:silk_js_actions] << action
    end
    
    def silk_layout(name)
      Rails.env.test? ? false : name
    end
    
    def request_login!
      silk_js_action "Silk.user.login();"
    end

end
