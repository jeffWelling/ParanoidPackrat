require 'PPackratConfig.rb'
require 'pp'

describe PPackratConfig do
	it "should contain no configs at startup" do
		p=PPackratConfig.new
		p.length.should==0
	end
	it "should add a name" do
		p=PPackratConfig.new
		p.addName 'jesusboots'
		p['jesusboots'].should==nil
	end
	it "should contain 1 config" do
		p=PPackratConfig.new
		p.length.should==1
	end
	it "adds a destination" do
		x=PPackratConfig.new
		x.addName 'Jesus has no boots'
		x.setBackupDestinationOn 'Jesus has no boots', '/mnt'
		x['Jesus has no boots'].should=={'BackupDestination'=>'/mnt'}
	end

end

