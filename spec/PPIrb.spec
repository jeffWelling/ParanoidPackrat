#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../spec"))

require 'ParanoidPackrat'
load 'PPIrb.rb'

describe PPIrb do
        before :each do
                @bdir = create_fake_backup_target
                #
        end
        it "simpleBackup performs a backup" do
                filename = make_fake_backup_file @bdir
                configure_backup 'test_backup', @bdir
                PPIrb.simpleBackup PPConfig['test_backup']
                filename_in_backup = PPIrb.getLastBackupFor PPConfig['test_backup'], filename
                sha(filename).should == sha(filename_in_backup)
        end
        it "simpleBackup identical backup of backupTarget, and puts it in backupDest/backup/backupName"

        it "by default stores two copies of a file that is in an initial backup, not the next, and is restored in the last"
        it "will hardlink this files to save space when shrink backup is run"

        #Need to make some fake datas, back them up, and examine the backup for this part.
        it "shrinkBackupDestination does not hardlink files which are not identical"
        it "shrinkBackupDestination does not hardlink two files if doing so would create a hardlink between files in the same backup instance"
        it "shrinkBackupDestination does not hardlink two files if the paths of those files are in the same backup instance"
        it "shrinkBackupDestination does not hardlink empty files"

end
