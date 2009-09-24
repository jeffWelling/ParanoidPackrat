#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require 'PPConfig'

describe PPConfig do
	it "contains no configs at startup" do
		PPConfig.length.should==0
	end
	it "add a backup source by name" do
		PPConfig.addName 'jesusboots'
		PPConfig['jesusboots'].should==nil
	end
	it "now contains one config" do
		PPConfig.length.should==1
	end
	it "takes a destination for a backup source" do
		PPConfig.addName 'Jesus has no boots'
		PPConfig.setBackupDestinationOn 'Jesus has no boots', '/mnt'
		PPConfig['Jesus has no boots'].should=={'BackupDestination'=>'/mnt'}
	end
end

