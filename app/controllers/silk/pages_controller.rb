class Silk::PagesController < Silk::BaseController
  
  before_filter :find_record, :only => [:update, :destroy]
    
  def show
    @page = Silk::Page.process(silk_path, silk_content[nil])
    render :inline => @page.body.to_s, :layout => silk_layout(@page.layout), :type => @page.content_type.to_sym
  rescue ActiveRecord::RecordNotFound
    requests_edit? ? redirect_to_edit : show_page_not_found
  rescue
     render :inline => render_error, :layout => silk_layout('application'), :type => :erb
  end
  
  def update
    if @page.update_attributes(params[:page])
      flash[:notice] = "Page updated successfully"
    else
      flash[:error] = "Error: Unable to update page"
    end
    redirect_to :back
  end
  
  def create
    @page = Silk::Page.new(params[:page])
    if @page.save
      flash[:notice] = "New page created successfully"
    else
      flash[:error] = "Error: Unable to create page"
    end
    redirect_to :back
  end
  
  def destroy
    if !@page.protected? and @page.destroy
      flash[:notice] = "Page deleted successfully"
      redirect_to '/'
    else
      flash[:error] = "Error: Unable to delete page"
      redirect_to :back
    end
  end


  private
  
    def find_record
      @page = Silk::Page.find(params[:id]) if params[:id]
    end
    
    def show_page_not_found
      silk_js_action "SilkPage.createNewPagePrompt('#{silk_path}');" if current_user
      render :inline => 'Page Not Found', :layout => silk_layout('application'), :status => 404
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
