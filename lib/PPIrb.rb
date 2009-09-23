=begin
		Copyright 2009 Jeff Welling (jeff.welling (a) gmail.com)
		This file is part of ParanoidPackrat.

    ParanoidPackrat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ParanoidPackrat is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with ParanoidPackrat.  If not, see <http://www.gnu.org/licenses/>.
=end
require 'fileutils'

#This module is intended to assist users while they are working with 
#ParanoidPackrat from IRB.  Basically, the executed ./ParanoidPackrat.rb
#file will interact with the IRB library, in a one on top of the other
#fashion.
module PPIrb
	#simpleBackup(backup) performs a simple backup.
	#backup is expected to be the hash from @Configs[name] .
	#It will;
	#	1. create a directory with the name of newDatetime() in the backup/name dir.
	#	2. perform an rsync -a --link-dest=../last_backup backupTarget backup/name/datetime/ .
	#	3. check entire backup/name dir recursively for duplicate files, and hardlink for single instance storage.
	#
	#In that order.  It returns the path that the backup was stored in, for example "/backupDest/backupName/datetime/"
	def self.simpleBackup(backup)
		date=PPCommon.newDatetime
		PPCommon.makeBackupDirectory(backup[:BackupDestination]) unless (
			File.exist?(backup[:BackupDestination]) and
			File.directory?(backup[:BackupDestination])
		)
		dest_name=PPCommon.addSlash(backup[:BackupDestination]) + 'backup/' + backup[:BackupName]
		FileUtils.mkdir_p(dest_name) unless File.exist?(dest_name)
		PPCommon.pprint("simpleBackup():  Fatal error, conflict between backup name and existing file/dir in backup destination.", :fatal) unless File.directory?(dest_name)
		dest_name_date=PPCommon.addSlash(dest_name) + PPCommon.addSlash(date)
		FileUtils.mkdir_p(dest_name_date) unless File.exist?(dest_name_date)
		pp backup
		if PPCommon.containsBackups?(backup[:BackupDestination], backup[:BackupName]).class==TrueClass
			puts "not first run"
			#This isn't the first backup, you can hardlink to the other backups.
			`rsync -a  --link-dest=../last_backup --log-file=#{dest_name_date.gsub(' ','\ ')}rsync_log.txt #{PPCommon.stripSlash(backup[:BackupTarget]).gsub(' ','\ ')} #{dest_name_date.gsub(' ','\ ')}`
			if $?.exitstatus==0
				File.unlink( PPCommon.addSlash(dest_name) + 'last_backup')
				File.symlink( dest_name_date, PPCommon.addSlash(dest_name) + 'last_backup' )
				#run the method to scan all of the backups for duplicates and hardlink them
				PPCommon.shrinkBackupDestination(backup)
			end
		else
			puts "first run"
			#This is the first backup.
			`rsync -a --log-file=#{dest_name_date.gsub(' ','\ ')}rsync_log.txt #{PPCommon.stripSlash(backup[:BackupTarget]).gsub(' ','\ ')} #{dest_name_date.gsub(' ','\ ')}`
			File.symlink( dest_name_date, PPCommon.addSlash(dest_name) + 'last_backup' ) if $?.exitstatus==0
		end
		PPCommon.pprint( 'simpleBackup():  Done with abnormal existatus - rsync gave non-zero exitstatus!' ) if $?.exitstatus!=0
		PPCommon.pprint( 'simpleBackup():  Done.  Check the log and the backups for bugs and errors.' )
		return dest_name_date
	end
end
