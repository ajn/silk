class Silk::ContentController < Silk::BaseController
  
  before_filter :find_record
  
  def update
    if @content.update_attributes(params[:content])
      silk_snippet_cache[@content.name] = @content if @content.snippet?
      flash[:notice] = "#{@content.name || 'Content'} updated successfully"
    else
      flash[:error] = "Error: Unable to update #{@content.name || 'content'}"
    end
    redirect_to :back
  end

  private

    def find_record
      @content = Silk::Content.find(params[:id]) if params[:id]
    end
  
end
