require 'spec_helper'

describe Silk::PagesController do
  
  fixtures :silk_pages, :silk_content

  describe "showing" do
    
    it "should serve up an existing page" do
      controller.stub!(:silk_path).and_return('/about_us')
      get :show
      response.should have_text("Welcome to About Us")
    end
    
    it "should have case-insensitive URLs" do
      controller.stub!(:silk_path).and_return('/About_US')
      get :show
      response.should have_text("Welcome to About Us")
    end
    
    it "should show rendering error if required" do
      controller.stub!(:silk_path).and_return('/invalid')
      get :show
      response.should have_tag("div.silk-content-render-error", /There was an error/)
    end
    
    describe 'requesting editing' do

      it "should redirect to edit user and strip off /edit" do
        controller.stub!(:silk_path).and_return('/about_us/edit')
        get :show
        session[:silk_return_url].should == '/about_us'
        response.should redirect_to('/about_us')
        session[:silk_js_actions].should == ["SilkPage.user.login();"]
      end
    
    end
    
    # Page Not Found handling will be improved greatly in future versions
    describe 'page not found' do
      
      def page_not_found_specs
        controller.stub!(:silk_path).and_return('/does_not_exist')
        get :show
        response.should have_text("Page Not Found")
        response.status.should == "404 Not Found"
      end
      
      it "should should display page and pop up dialog if logged in" do
        controller.stub!(:current_user).and_return(true)
        page_not_found_specs
        session[:silk_js_actions].should == ["SilkPage.createNewPagePrompt('/does_not_exist');"]
        controller.should be_silk_load
      end
      
      it "should should display page but no dialog if not logged in" do
        controller.stub!(:current_user).and_return(nil)
        page_not_found_specs
        session[:silk_js_actions].should == nil
        controller.should_not be_silk_load
      end
    
    end
    
  end
  
  describe "updating" do
    
    before(:each) do
      request.env["HTTP_REFERER"] = '/about_us'
      @page = Silk::Page.find_by_path('/about_us')
    end
    
    it "should update successfully and show flash" do
      post :update, :id => @page.id, :page => { :title => 'New Title', :content_attributes => {:body => 'New body content'} }
      assigns[:page].title.should == 'New Title'
      assigns[:page].body.should == 'New body content'
      flash[:notice].should == "Page updated successfully"
      response.should redirect_to('/about_us')
    end
    
    it "should show error if unable to update" do
      page = mock_model(Silk::Page, :id => 24, :title => 'Existing title', :body => 'Existing body')
      page.should_receive(:update_attributes).and_return(false)
      Silk::Page.should_receive(:find).with("24").and_return(page)
      post :update, :id => 24, :page => { :title => 'New Title', :content_attributes => {:body => 'New body content'} }
      flash[:error].should == "Error: Unable to update page"
      response.should redirect_to('/about_us')
    end
    
  end
  
  describe "creating" do
    
    before(:each) do
      request.env["HTTP_REFERER"] = '/new_page'
    end
    
    it "should create successfully and show flash" do
      post :create, :page => { :path => '/new_page' }
      assigns[:page].path.should == '/new_page'
      assigns[:page].title.should == nil
      assigns[:page].body.should == nil
      flash[:notice].should == "New page created successfully"
      response.should redirect_to('/new_page')
    end
    
    it "should show error if unable to create" do
      page = mock_model(Silk::Page, :path => '/new_page')
      page.should_receive(:save).and_return(false)
      Silk::Page.should_receive(:new).and_return(page)
      post :create, :page => { :path => '/new_page' }
      flash[:error].should == "Error: Unable to create page"
      response.should redirect_to('/new_page')
    end
    
  end
  
  describe 'deleting' do
    
    describe 'non protected pages (e.g homepage)' do
    
      before(:each) do
        request.env["HTTP_REFERER"] = '/about_us'
        @page = Silk::Page.find_by_path('/about_us')
      end

      it "should delete successfully and show flash" do
        delete :destroy, :id => @page.id
        flash[:notice].should == "Page deleted successfully"
        response.should redirect_to('/')
      end
    
      it "should show error if unable to delete" do
        page = mock_model(Silk::Page, :id => 24, :title => 'Existing title', :body => 'Existing body')
        page.should_receive(:protected?).and_return(false)
        page.should_receive(:destroy).and_return(false)
        Silk::Page.should_receive(:find).with("24").and_return(page)
        delete :destroy, :id => 24
        flash[:error].should == "Error: Unable to delete page"
        response.should redirect_to('/about_us')
      end
    
    end
    
    describe 'protected pages (e.g. homepage)' do

      before(:each) do
        request.env["HTTP_REFERER"] = '/'
        @page = Silk::Page.find_by_path('/')
      end
      
      it "should delete successfully and show flash" do
        delete :destroy, :id => @page.id
        flash[:error].should == "Error: Unable to delete page"
        response.should redirect_to('/')
      end

    end
    
  end


end
