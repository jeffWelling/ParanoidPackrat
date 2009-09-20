#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require 'PPackratConfig'
require 'PPCommon'
require 'prettyprint'

describe PPackratConfig do
	it "contains no configs at startup" do
		PPackratConfig.length.should==0
	end
	it "add a backup source by name" do
		PPackratConfig.addName 'jesusboots'
		PPackratConfig['jesusboots'].should==nil
	end
	it "now contains one config" do
		PPackratConfig.length.should==1
	end
	it "takes a destination for a backup source" do
		PPackratConfig.addName 'Jesus has no boots'
		PPackratConfig.setBackupDestinationOn 'Jesus has no boots', '/mnt'
		PPackratConfig['Jesus has no boots'].should=={'BackupDestination'=>'/mnt'}
	end
end

describe PPCommon do
  it "scans a path, returning it or all files under it that were not specifically excluded"

end
