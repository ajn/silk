require 'spec_helper'

describe Silk::SessionsController do
  
  fixtures :silk_users

  describe "new (login)" do
    
    it "should redirect with login JS action" do
      get :new
      response.should redirect_to('/')
      session[:silk_js_actions].should == ["SilkPage.user.login();"]
    end
    
  end
  
  describe "create (login with user/pass)" do
    
    describe "with correct credentials" do
      
      it "should log you in and return to / by default" do
        post :create, :user => { :login => 'admin', :password => 'password' }
        flash[:notice].should == "Hello admin. You are now logged in"
        response.should redirect_to('/')
      end

      it "should log you and redirect to silk_return_url if set" do
        session[:silk_return_url] = '/about'
        post :create, :user => { :login => 'admin', :password => 'password' }
        flash[:notice].should == "Hello admin. You are now logged in"
        response.should redirect_to('/about')
        session[:silk_return_url].should == nil # should remove once used
      end

    end
    
    describe "with incorrect credentials" do
      
      it "should log you in and return to / by default" do
        post :create, :user => { :login => 'micky', :password => 'mouse' }
        flash[:inline_error].should == "Sorry. Incorrect username or password"
        response.should redirect_to('/')
        session[:silk_js_actions].should == ["SilkPage.user.login();"]
      end

      it "should log you and redirect to silk_return_url if set" do
        session[:silk_return_url] = '/about'
        post :create, :user => { :login => 'micky', :password => 'mouse' }
        flash[:inline_error].should == "Sorry. Incorrect username or password"
        response.should redirect_to('/about')
        session[:silk_js_actions].should == ["SilkPage.user.login();"]
        session[:silk_return_url].should == '/about' # should keep and re-use
      end

    end
    
  end
  
  describe "destroy (logout)" do
    
    it "should remove current_user_session" do
      cus = mock_model(Silk::UserSession)
      cus.should_receive(:destroy)
      controller.should_receive(:current_user_session).and_return(cus)
      delete :destroy
      session[:silk_load].should be_true
      flash[:notice].should == "Thank you. You are now logged out"
      response.should redirect_to('/')
    end
    
    it "should not error if you logout more than once"
    
  end
    
end
