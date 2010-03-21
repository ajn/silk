require 'spec_helper'

describe Silk::Content do
  
  describe "existing content" do
    
    fixtures :silk_content
  
    describe "processing/displaying content" do
    
      it "should find existing sidebar content" do
        content = Silk::Content.process('/about_us', 'Sidebar', nil)
        content.should be_instance_of(Silk::Content)
        content.body.should == 'About Us Sidebar'
      end
      
      it "should find existing footer snippet" do
        content = Silk::Content.process('/about_us', 'Footer', nil, :snippet => true)
        content.should be_instance_of(Silk::Content)
        content.body.should == 'Silk Footer'
      end

      it "should create new un-reusable content record without initial content" do
        content = Silk::Content.process('/about_us', 'Contact Us Details', nil)
        content.should be_instance_of(Silk::Content)
        content.body.should == nil
        content.path.should == '/about_us'
        content.name.should == 'Contact Us Details'
      end

      it "should create new un-reusable content record with initial content" do
        content = Silk::Content.process('/about_us', 'About Us Details', 'My initial content')
        content.should be_instance_of(Silk::Content)
        content.body.should == 'My initial content'
        content.path.should == '/about_us'
        content.name.should == 'About Us Details'
      end
      
      it "should create new snippet content record with initial content" do
        content = Silk::Content.process('/about_us', 'Footer Main', 'Copyright Silk', :snippet => true)
        content.should be_instance_of(Silk::Content)
        content.body.should == 'Copyright Silk'
        content.path.should == nil
        content.name.should == 'Footer Main'
      end
      
      it "should save and reload newly created content before returing object" do
        content = Silk::Content.process('/about_us', 'Something new', nil)
        content.should be_instance_of(Silk::Content)
        content.should_not be_new_record
      end

    end
  
    describe "getting all content for a path" do
  
      it 'should load all content for that path to minimise db calls (used to preload and then cache content)' do
        content = Silk::Content.all_for_path('/about_us')
        content.size.should == 4
        content.keys.compact.sort.should == ["Header", "Invalid", "Sidebar"]
      end
    
      it 'should return empty hash if no matching content' do
        content = Silk::Content.all_for_path('/does_not_exist')
        content.should == {}
      end
  
    end
    
  end
  
  describe "identifying content" do
  
    it 'should identify snippets' do
      content = Silk::Content.new(:path => nil, :body => 'Test', :name => 'Footer')
      content.should be_snippet
      content.should_not be_page_content
    end

    it 'should identify page content' do
      content = Silk::Content.new(:path => '/about_us', :body => 'Test', :name => nil)
      content.should_not be_snippet
      content.should be_page_content
    end

    it 'should identify normal content' do
      content = Silk::Content.new(:path => '/about_us', :body => 'Test', :name => 'Sidebar')
      content.should_not be_snippet
      content.should_not be_page_content
    end
  
  end

  describe "content types" do

    it "should give a list of allowed content types" do
      Silk::Content.allowed_types['html'].should == ({"label"=>"Static HTML", "type"=>"html"})
    end

    it "should contain a list of supported types" do
      output = defined?(Haml) ? ["erb", "haml", "html", "plain"] : ["erb", "html", "plain"]
      Silk::Content.supported_content_types.should == output
    end
  
    describe "default type" do

      it "should return default type if a valid type is specified in preferences" do
        Silk::Preference.should_receive(:get).with(:default_content_type).and_return('plain')
        Silk::Content.default_type.should == 'plain'
      end

      it "should return html if an invalid type specified" do
        Silk::Preference.should_receive(:get).with(:default_content_type).and_return('invalid')
        Silk::Content.default_type.should == 'html'
      end

      it "should return html if nothing specified" do
        Silk::Preference.should_receive(:get).with(:default_content_type).and_return(nil)
        Silk::Content.default_type.should == 'html'
      end

    end

    describe "returning the given content_type if it's allowed, or returning the default" do

      it "should return the given content_type if it is allowed" do
        Silk::Content.valid_type_or_default('erb').should == 'erb'
      end

      it "should fall back on default if given content_type is not allowed" do
        Silk::Content.should_receive(:default_type).and_return('haml')
        Silk::Content.valid_type_or_default('invalid!').should == 'haml'
      end

    end

    describe "sanitizing allowed content types" do

      it "should allow valid ones and reject unspported types" do
        Silk::Preference.should_receive(:get).with(:allowed_content_types).and_return([{"label"=>"Valid HTML", "type"=>"html"}, {"label"=>"INVALID!", "type"=>"invalid"}])
        Silk::Content.sanitized_allowed_types.should == {"html" => {"label"=>"Valid HTML", "type"=>"html"}}
      end

    end
    
    describe "content_type in attributes (read by silk.js)" do

      it 'should read back content_type in attributes if specified' do
        content = Silk::Content.new(:content_type => 'plain')
        content.content_type.should == 'plain'
        content.attributes[:content_type].should == 'plain'
      end

      it 'should default to html content_type in attrubutes if invalid type specified' do
        content = Silk::Content.new(:content_type => 'invalid type!')
        content.content_type.should == 'html'
        content.attributes[:content_type].should == 'html'
      end
    
      it 'should default to html content_type in attrubutes if not specified' do
        content = Silk::Content.new
        content.content_type.should == 'html'
        content.attributes[:content_type].should == 'html'
      end
    
    end

  end
  
  describe "before validating" do
    
    it "should strip the whitespace off the ends of the body" do
      content = Silk::Content.new(:body => ' This is my content  ')
      content.valid?
      content.body.should == 'This is my content'
    end
    
    it "should ensure content is saved with default content_type if not specified" do
      Silk::Preference.should_receive(:get).with(:default_content_type).and_return('erb')
      content = Silk::Content.new(:body => 'Test')
      content.valid?
      content.body.should == 'Test'
      content.send(:read_attribute, :content_type).should == 'erb'
    end
    
  end
  
  describe "rendering" do
    
    it "should render in Erb" do
      Silk::Content.new(:body => '<%= 5+5 %> elephants', :content_type => 'erb').render.should == "10 elephants"
    end
    
    it "should render in HAML with some helpers" do
      Silk::Content.new(:body => "%p Test\n= link_to 'test', '/'", :content_type => 'haml').render.should == "<p>Test</p>\n<a href=\"/\">test</a>\n" if defined?(Haml)
    end
    
    it "should render Plain (normal html but convert line spaces to <br> tags)" do
      Silk::Content.new(:body => "test content\non new line", :content_type => 'plain').render.should == "<p>test content\n<br />on new line</p>"
    end
    
    it "should render HTML" do
      Silk::Content.new(:body => "<%= 5+5 %> elephants\nNo br tag here", :content_type => 'html').render.should == "<%= 5+5 %> elephants\nNo br tag here"
    end
    
  end

end
