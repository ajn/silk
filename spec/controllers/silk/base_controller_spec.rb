require 'spec_helper'

describe Silk::BaseController do
  
  fixtures :silk_pages, :silk_content

  it "should initiate snippet cache" do
    controller.silk_snippet_cache.should_not be_nil
  end
  
  it "should hide all actions apart from index" do
    controller.send(:action_methods).to_a.should == ["index"]
  end

  describe "for each request" do
    
    it "should preload all silk content for that page" do
      controller.stub!(:silk_path).and_return('/about_us')
      get :index
      controller.silk_content.should have(4).content
    end
    
    describe "users" do
    
      it "should return current_user_session" do
        Silk::UserSession.should_receive(:find)
        controller.send(:current_user_session)
      end
    
      it "should return current_user" do
        controller.should_receive(:current_user_session)
        controller.send(:current_user)
      end
      
    end
    
    describe "silk_editable?" do
      
      it "should not be true if no user and no page" do
        controller.should_receive(:current_user).and_return(false)
        controller.send(:silk_editable?).should be_false
      end
      
      it "should not be true if user and no page" do
        controller.should_receive(:current_user).and_return(Silk::User.new)
        controller.send(:silk_editable?).should be_false
      end
      
      it "should not be true if no user but page" do
        controller.instance_variable_set("@page", Silk::Page.new)
        controller.should_receive(:current_user).and_return(false)
        controller.send(:silk_editable?).should be_false
      end

      it "should be true if user and page" do
        controller.instance_variable_set("@page", Silk::Page.new)
        controller.should_receive(:current_user).and_return(Silk::User.new)
        controller.send(:silk_editable?).should be_true
      end
      
    end
    
    describe "silk_load?" do

      it "should be true if silk_load was set in session" do
        session[:silk_load] = true
        controller.send(:silk_load?).should be_true
      end
      
      it "should ensure session is accessed before :silk_load is deleted (due to rails lazy-loading of sessions)" do
        session[:silk_load] = true
        session.should_receive(:[]).with(:silk_load).and_return(true)
        controller.send(:silk_load?).should be_true
      end
            
      it "should always load if page is editable" do
        controller.should_receive(:silk_editable?).and_return(true)
        controller.send(:silk_load?).should be_true
      end
      
      it "should not load if no session var set or not silk_editable?" do
        controller.send(:silk_load?).should be_false
      end
      
    end
    
  end

end
