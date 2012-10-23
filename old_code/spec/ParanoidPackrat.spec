#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

p __FILE__
require 'ParanoidPackrat'

describe ParanoidPackrat do
  it "backs up files with a specified redundancy and geo-seperation" do
#    dir = tmpdir
#    ParanoidPackrat.establishRedundancy :dir => dir, :redundancy => 3, :continents => 2
#    
#    ParanoidPackrat.checkRepositorySafe(dir).should == true
  end
end

