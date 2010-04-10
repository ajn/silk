class Silk::PagesController < Silk::BaseController
  
  before_filter :find_record, :only => [:update, :destroy]
    
  def show
    @page = Silk::Page.process(silk_path, silk_content[nil])
    render :inline => @page.body.to_s, :layout => silk_layout(@page.layout), :type => @page.content_type.to_sym
  rescue ActiveRecord::RecordNotFound
    requests_edit? ? redirect_to_edit : show_page_not_found
  rescue
     render :inline => render_error, :layout => silk_layout('silk'), :type => :erb
  end
  
  def update
    if @page.update_attributes(params[:page])
      redirect_to :back, :notice => "Page updated successfully"
    else
      redirect_to :back, :error => "Error: Unable to update page"
    end
  end
  
  def create
    @page = Silk::Page.new(params[:page])
    if @page.save
      redirect_to :back, :notice => "New page created successfully"
    else
      redirect_to :back, :error => "Error: Unable to create page"
    end
  end
  
  def destroy
    if !@page.protected? and @page.destroy
      redirect_to root_path, :notice => "Page deleted successfully"
    else
      redirect_to :back, :error => "Error: Unable to delete page"
    end
  end


  private
  
    def find_record
      @page = Silk::Page.find(params[:id]) if params[:id]
    end
    
    def show_page_not_found
      silk_js_action "Silk.page.createNewPagePrompt('#{silk_path}');" if current_user
      render :inline => 'Page Not Found', :layout => silk_layout('silk'), :status => 404
    end
    
    def requests_edit?
      silk_path.split('/').last =~ /^edit/i
    end
    
    def redirect_to_edit
      session[:silk_return_url] = silk_path[0..-6]
      request_login!
      redirect_to session[:silk_return_url]
    end
    
    def render_error
      '<div class="silk-content-render-error">Oops! There was an error with the code</div><br/><pre><%= h $! %></pre>'
    end
  
end
