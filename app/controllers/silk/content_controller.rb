class Silk::ContentController < Silk::BaseController
  
  before_filter :find_record
  
  def update
    if @content.update_attributes(params[:content])
      silk_snippet_cache[@content.name] = @content if @content.snippet?
      redirect_to :back, :notice => "#{@content.name || 'Content'} updated successfully"
    else
      redirect_to :back, :error => "Error: Unable to update #{@content.name || 'content'}"
    end
  end

  private

    def find_record
      @content = Silk::Content.find(params[:id]) if params[:id]
    end
  
end
