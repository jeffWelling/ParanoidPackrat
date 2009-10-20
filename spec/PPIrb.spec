#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../spec"))

require 'ParanoidPackrat'
load 'PPIrb.rb'

describe PPIrb do
        before :all do
                @bdir = create_fake_backup
                #
        end
        it "simpleBackup performs a backup of a file and directory" do
                filename = make_fake_backup_file(@bdir+'/stuffs')
                configure_backup 'test_backup', @bdir
                PPConfig.silentMode
                PPIrb.simpleBackup PPConfig['test_backup']
                PPConfig.silentMode
                filename_in_backup = PPCommon.getLastBackupFor(PPConfig['test_backup']).chop+filename  #.chop for extraneous '/'
                PPCommon.sha1(@bdir + filename).should == PPCommon.sha1(filename_in_backup)
        end
        it "simpleBackup identical backup of backupTarget, and puts it in backupDest/backup/backupName"

        it "by default stores two copies of a file that is in an initial backup, not the next, and is restored in the last"
        it "will hardlink this files to save space when shrink backup is run"

        #Need to make some fake datas, back them up, and examine the backup for this part.
        dir=create_fake_backup_target
        PPIrb.shrinkBackupDestination(PPConfig['test_backup'], nil, nil)
        it "shrinkBackupDestination does not hardlink files which are not identical" do
               Dir.glob(dir.gsub(/\/stuffs$/,  '') + '/dest/backup/test_backup/*').each {|path_datetime|
                       #obviously these should never match either
                       File.stat(path_datetime + '/stuffs/never_changes.txt').ino.should_not ==
                       File.stat(path_datetime + '/stuffs/always_changing.txt').ino

                       #the inodes of 'always_changing.txt' should never match
                       Dir.glob(dir.gsub(/\/stuffs$/,  '') + '/dest/backup/test_backup/*').each {|path_datetime2|
                                next if path_datetime == path_datetime2 || (path_datetime2[/last_backup$/] or path_datetime[/last_backup$/])
                                File.stat(path_datetime + '/stuffs/always_changing.txt').ino.should_not == 
                                File.stat(path_datetime2 + '/stuffs/always_changing.txt').ino
                       }
               }
        end

        it "shrinkBackupDestination does not hardlink two files if doing so would create a hardlink between files in the same backup instance"
        it "shrinkBackupDestination does not hardlink two files if the paths of those files are in the same backup instance"
        it "shrinkBackupDestination does not hardlink empty files"
        PPConfig.resetConfigs
        FileUtils.rm_rf dir.gsub(/\/stuffs$/,  '')

end
