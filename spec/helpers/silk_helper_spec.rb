require 'spec_helper'

describe SilkHelper do

  describe "title (used within pages)" do
    
    describe "when set manually" do

      it "should return @page_title if no args supplied" do
        helper.instance_variable_set(:@page_title, 'Test A')
        helper.title.should == 'Test A'
      end

      it "should set @page_title var for use in the content" do
        helper.title('Test B')
        helper.instance_variable_get(:@page_title).should == 'Test B'
      end

      it "should set @page_title var and output tag for use in the content" do
        helper.title('Test C', :h1).should == "<h1>Test C</h1>"
        helper.instance_variable_get(:@page_title).should == 'Test C'
      end
      
    end
    
    describe "when using title from DB page" do

      it "should output title from page" do
        helper.instance_variable_set(:@page, Silk::Page.new(:title => 'Dynamic Page Title'))
        helper.title.should == 'Dynamic Page Title'
      end
      
      it "should output title from page with tag" do
        helper.instance_variable_set(:@page, Silk::Page.new(:title => 'Dynamic Page Title'))
        helper.title(:h3).should == '<h3>Dynamic Page Title</h3>'
      end
      
      it "should prefer DB title to manual title" do
        helper.instance_variable_set(:@page_title, 'Set Page Title')
        helper.instance_variable_set(:@page, Silk::Page.new(:title => 'Dynamic Page Title'))
        helper.title.should == 'Dynamic Page Title'
      end
      
    end
    
  end
  
  describe "page_title (used within the title tags of a layout)" do
    
    it "should obtain the title from the title() helper and output nothing else" do
      helper.should_receive(:title).and_return('Test A')
      helper.page_title().should == 'Test A'
    end
    
    it "should return title with prefix" do
      helper.title('Test A')
      helper.page_title(:prefix => 'Test Website').should == 'Test Website : Test A'
      helper.page_title(:prefix => 'Test Website', :separator => '|').should == 'Test Website | Test A'
    end

    it "should return title with suffix" do
      helper.title('Test A')
      helper.page_title(:suffix => 'Test Website').should == 'Test A : Test Website'
      helper.page_title(:suffix => 'Test Website', :separator => '|').should == 'Test A | Test Website'
    end
    
    it "should return title with prefix and suffix (not quite sure why you'd want this!)" do
      helper.title('Test A')
      helper.page_title(:prefix => 'First', :suffix => 'Last').should == 'First : Test A : Last'
      helper.page_title(:prefix => 'First', :suffix => 'Last', :separator => '|').should == 'First | Test A | Last'
    end
    
  end
  
  describe "silk headers" do
    
    describe "always" do
      
      before(:each) do
        assigns[:page] = Silk::Page.new(:meta_tags => [{'name' => 'robots', 'content' => 'will rule the world'},{'name' => 'bender', 'content' => 'will be king'}])
        helper.should_receive(:silk_load?).and_return(false)
        @headers = helper.silk_headers
      end
      
      it "should include meta tags" do
        @headers.should == "<meta name=\"robots\" content=\"will rule the world\"/>\n<meta name=\"bender\" content=\"will be king\"/>\n"
      end
      
    end
    
    describe "when system files required (when logged in and when loggin in and out)" do

      before(:all) do
        helper.stub!(:silk_js_actions).and_return(['Silk.testAction()'])
        helper.stub!(:session).and_return({})
        helper.stub!(:current_user).and_return(false)
        helper.stub!(:silk_load?).and_return(true)
        @headers = helper.silk_headers
      end

      it "should include jquery calls" do
        @headers.should include('jquery')
      end

      it "should include _silk_data var" do
        @headers.should include('_silk_data =')
      end

      it "should include silk files" do
        @headers.should include('silk.js')
        @headers.should include('silk.css')
      end
      
      it "should output the js_actions" do
        @headers.should include("Silk.testAction()")
      end
      
    end
    
    describe "when not logged in" do

      it "should output empty string" do
        helper.should_receive(:silk_load?).and_return(false)
        helper.silk_headers.should == ''
      end

    end

  end
  
  describe "page content" do
    
    it "should output normally if not logged in" do
      helper.should_receive(:silk_editable?).and_return(false)
      helper.instance_variable_set(:@content_for_layout, 'Test')
      helper.page_content.should == 'Test'
    end
    
    it "should output with wrapper if editor logged in and this is a dynamic page" do
      helper.should_receive(:silk_editable?).and_return(true)
      helper.instance_variable_set(:@page, Silk::Page.new)
      helper.instance_variable_set(:@content_for_layout, 'Test')
      helper.page_content.should == "<div ondblclick=\"SilkPage.edit();\" title=\"Double click to edit page\">Test</div>" 
    end
    
  end

  describe "editable content helpers" do
    
    fixtures :silk_content
    
    before(:each) do
      helper.send(:controller).stub!(:silk_path).and_return('/about_us')
    end
    
    describe "when logged in as an editor" do
      
      before(:each) do
        helper.stub!(:silk_editable?).and_return(true)
        helper.stub!(:silk_load?).and_return(true)
      end
      
      describe "editable content (specific to that page)" do
        
        it "should output existing content if found by name" do
          content = Silk::Content.find_by_path_and_name('/about_us','Sidebar')
          output = helper.editable('Sidebar')
          output.should have_tag("div#silk-ec-area-id-#{content.id}[class=?]", 'silk-editable-content silk-editable-content-normal', content.body)
          output.should have_tag('script', /_silk_data/)
        end

        it "should create new content and output an empty string if no initial content supplied" do
          output = helper.editable('New Content')
          content = Silk::Content.find_by_path_and_name('/about_us','New Content')
          output.should have_tag("div#silk-ec-area-id-#{content.id}[class=?]", 'silk-editable-content silk-editable-content-normal', '')
          output.should have_tag('script', /_silk_data/)
        end
        
        it "should output content rendering error if content is invalid" do
          content = Silk::Content.find_by_path_and_name('/about_us','Invalid')
          output = helper.editable('Invalid')
          output.should have_tag("div#silk-ec-area-id-#{content.id}[class=?]", 'silk-editable-content silk-editable-content-normal', /Content Render Error/)
          output.should have_tag('script', /_silk_data/)
        end
        
      end
      
      describe "snippet content (re-usable on multiple pages)" do
        
        it "should output existing content if found by name" do
          content = Silk::Content.find_by_path_and_name(nil,'Footer')
          output = helper.snippet('Footer')
          output.should have_tag("div#silk-ec-area-id-#{content.id}[class=?]", 'silk-editable-content silk-editable-content-snippet', content.body)
          output.should have_tag('script', /_silk_data/)
        end

        it "should create new content and output an empty string if no initial content supplied" do
          output = helper.snippet('New Snippet')
          content = Silk::Content.find_by_path_and_name(nil,'New Snippet')
          output.should have_tag("div#silk-ec-area-id-#{content.id}[class=?]", 'silk-editable-content silk-editable-content-snippet', '')
          output.should have_tag('script', /_silk_data/)
        end
        
        it "should output content rendering error if content is invalid" do
          content = Silk::Content.find_by_path_and_name(nil,'Invalid')
          output = helper.snippet('Invalid')
          output.should have_tag("div#silk-ec-area-id-#{content.id}[class=?]", 'silk-editable-content silk-editable-content-snippet', /Content Render Error/)
          output.should have_tag('script', /_silk_data/)
        end
        
      end
      
      # TODO: Find out how to test editable/snippet helpers with initial content passed as a block
      
    end
    
    describe "when not logged in (e.g. regular visitor)" do
      
      before(:each) do
        helper.stub!(:silk_editable?).and_return(false)
        helper.stub!(:silk_load?).and_return(false)
      end
      
      describe "editable content (specific to that page)" do
      
        it "should output existing normal content by name" do
          helper.editable('Sidebar').should == 'About Us Sidebar'
        end

        it "should output empty string if normal content not found" do
          helper.editable('Non-existing content').should == ''
        end
        
        it "should output empty string if invalid content rendered" do
          helper.editable('Invalid').should == ''
        end
      
      end
      
      describe "snippet content (re-usable on multiple pages)" do
      
        it "should output existing snippet content by name" do
          helper.snippet('Footer').should == 'Silk Footer'
        end

        it "should output empty string if snippet not found" do
          helper.snippet('New Footer').should == ''
        end
        
        it "should output empty string if invalid content rendered" do
          helper.snippet('Invalid').should == ''
        end
        
      end
      
    end
    
  end

end
