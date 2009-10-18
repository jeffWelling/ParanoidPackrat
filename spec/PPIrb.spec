#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../spec"))

require 'ParanoidPackrat'
load 'PPIrb.rb'

describe PPIrb do
        it "simpleBackup performs a backup"
        it "simpleBackup identical backup of backupTarget, and puts it in backupDest/backup/backupName"

        #Need to make some fake datas, back them up, and examine the backup for this part.
        it "shrinkBackupDestination does not hardlink files which are not identical"
        it "shrinkBackupDestination does not hardlink two files if doing so would create a hardlink between files in the same backup instance"
        it "shrinkBackupDestination does not hardlink two files if the paths of those files are in the same backup instance"
        it "shrinkBackupDestination does not hardlink empty files"

end
