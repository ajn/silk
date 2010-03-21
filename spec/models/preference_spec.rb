require 'spec_helper'

describe Silk::Preference do

  it "should raise error if YAML file is missing or incorrect" do
    Silk::Preference.silk_preferences = nil
    Silk::Preference.should_receive(:load_from_file).and_raise('Can not find file')
    lambda{ Silk::Preference.preferences }.should raise_error
  end
  
  it "should load preference file without errors" do
    Silk::Preference.preferences.should be_instance_of(Hash)
  end
  
  it "should get a particular preference" do
    Silk::Preference.get('default_content_type').should == 'html'
  end

end
