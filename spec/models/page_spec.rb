require 'spec_helper'

describe Silk::Page do

  describe "association with content" do
    
    it "should accept nested attributes (test association directly)" do
      page = Silk::Page.new(:path => '/testing_new')
      page.update_attributes(:content_attributes => {:body => 'test content'})
      page.content.should be_instance_of(Silk::Content)
      page.content.body.should == 'test content'
    end
    
    it "should allow injection of cached content (used when preloading all content for page)" do
      page = Silk::Page.new
      page.cached_content = Silk::Content.new(:body => 'test content')
      page.cached_content.body.should == 'test content'
      page.cached_content.content_type.should == 'html'
    end
    
    it "should delegate body and content_type methods to cached_content" do
      page = Silk::Page.new
      page.should_receive(:cached_content).twice.and_return(Silk::Content.new(:body => 'test content'))
      page.body.should == 'test content'
      page.content_type.should == 'html'
    end
    
    it "should include delegated methods in attributes (for use by silk.js)" do
      page = Silk::Page.new
      page.should_receive(:cached_content).twice.and_return(Silk::Content.new(:body => 'test content', :content_type => 'plain'))
      attributes = page.attributes
      attributes[:body].should == 'test content'
      attributes[:content_type].should == 'plain'
    end
    
  end
  
  describe "processing/displaying page" do
    
    fixtures :silk_pages

    it "should raise error in no matching page found" do
      lambda{ Silk::Page.process('/not_here', nil) }.should raise_error(ActiveRecord::RecordNotFound)
    end
    
    it "should find page and inject pre-cached content before returning" do
      precached_content = Silk::Content.new(:body => 'test content')
      page = Silk::Page.process('/about_us', precached_content)
      page.title.should == 'About Us'
      page.cached_content.should == precached_content
    end
    
    it "should only protect the root page (from deletion)" do
      Silk::Page.process('/about_us', nil).should_not be_protected
      Silk::Page.process('/', nil).should be_protected
    end
    
  end
  
  describe "layout" do
    
    it "should default to 'application' when no layout" do
      page = Silk::Page.new
      page.layout.should == 'application'
    end
    
    it "should return given layout if supplied (not validated at this stage)" do
      page = Silk::Page.new(:layout => 'something_else')
      page.layout.should == 'something_else'
    end

  end

  describe "layouts and validating" do
    
    it "should return a complete sorted list of valid layouts available" do
      Dir.stub!(:entries).and_return([".", "..", "alternative.html.haml", "application.html.haml"])
      Silk::Page.find_layouts.should == ["alternative", "application"]
    end
    
    it "should accept valid layout" do
      Silk::Page.should_receive(:available_layouts).and_return(['alternative','application'])
      page = Silk::Page.new(:layout => 'alternative')
      page.should be_valid
      page.read_attribute(:layout).should == 'alternative'
    end
    
    it "should reject invalid layout and default to 'application'" do
      page = Silk::Page.new(:layout => 'invalid!')
      page.should be_valid
      page.read_attribute(:layout).should be_nil
    end
    
  end  

end
