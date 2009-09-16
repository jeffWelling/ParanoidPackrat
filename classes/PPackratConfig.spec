require 'PPackratConfig.rb'
require 'pp'

describe PPackratConfig do
	it "should contain no configs at startup" do
		PPackratConfig.length.should==0
	end
	it "should add a name" do
		PPackratConfig.addName 'jesusboots'
		PPackratConfig['jesusboots'].should==nil
	end
	it "should contain 1 config" do
		PPackratConfig.length.should==1
	end
	it "adds a destination" do
		PPackratConfig.addName 'Jesus has no boots'
		PPackratConfig.setBackupDestinationOn 'Jesus has no boots', '/mnt'
		PPackratConfig['Jesus has no boots'].should=={'BackupDestination'=>'/mnt'}
	end

end

