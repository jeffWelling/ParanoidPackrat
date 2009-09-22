#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require 'PPCommon'

describe PPCommon do
  it "creates an empty temp directory on request" do
    td = PPCommon.mktempdir
    File.exists?(   td).should == true
    File.directory?(td).should == true
  end

  it "scans a path, returning it or all files under it that were not specifically excluded"

end
