require 'spec_helper'

SPEC_SOURCE_DIR = "#{RAILS_ROOT}/tmp/test_source_dir"
SPEC_DEST_DIR   = "#{RAILS_ROOT}/tmp/test_destination_dir"

def make_example_source_dir!
  cleanup!
  FileUtils.mkdir_p "#{SPEC_SOURCE_DIR}/folder/in_a/folder"
  FileUtils.touch "#{SPEC_SOURCE_DIR}/folder/in_a/folder/a_file"
end

def cleanup!
  FileUtils.remove_dir SPEC_SOURCE_DIR rescue nil
  FileUtils.remove_dir SPEC_DEST_DIR rescue nil
end

describe Silk do
  
  describe "mirroring files" do
    
    before(:each) do
      make_example_source_dir!
    end
    
    after(:each) do
      cleanup!
    end
    
    it "should mirror files from one directory to another" do
      lambda{ Silk.mirror_files_from(SPEC_SOURCE_DIR, SPEC_DEST_DIR) }.should_not raise_error
      File.exists?("#{SPEC_DEST_DIR}/folder/in_a/folder/a_file").should be_true
    end

  end
  
end