require 'spec_helper'

describe Silk::ContentController do
  
  # Calling fixutures in controllers is not idea, but we have to write a lot less code this way - and it is a better test
  fixtures :silk_content

  describe "updating content" do
    
    before(:each) do
      Silk::Content.stub!(:all_for_path) # don't let this request in Base controller interfere with mocking
      request.env["HTTP_REFERER"] = '/original_page'
    end
    
    describe "normal content" do

      it "should update and show correct flash message" do
        content = Silk::Content.find_by_path_and_name('/about_us', 'Sidebar')
        post :update, :id => content.id, :content => {:body => 'Test Content'}
        flash[:notice].should == "Sidebar updated successfully"
        controller.silk_snippet_cache['Sidebar'].should be_nil
        response.should redirect_to('/original_page')
      end
      
      it "should show error message if update failed" do
        content = mock_model(Silk::Content, :name => 'Test', :body => 'Test')
        content.should_receive(:update_attributes).and_return(false)
        Silk::Content.should_receive(:find).with("10").and_return(content)
        post :update, :id => "10"
        flash[:error].should == "Error: Unable to update Test"
        response.should redirect_to('/original_page')
      end
      
    end
    
    describe "snippet content" do

      it "should update, update snippet cache and show correct flash message" do
        content = Silk::Content.find_by_path_and_name(nil, 'Footer')
        post :update, :id => content.id, :content => {:body => 'Test Content'}
        flash[:notice].should == "Footer updated successfully"
        controller.silk_snippet_cache['Footer'].should be_instance_of(Silk::Content)
        response.should redirect_to('/original_page')
      end
      
    end
    
  end

end
