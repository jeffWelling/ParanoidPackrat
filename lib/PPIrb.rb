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
		PPCommon.pprint("simpleBackup():  Performing simple backup, '#{backup[:BackupTarget]}'  to  '#{backup[:BackupDestination]}'")
		PPCommon.pprint( "simpleBackup():  Running garbage collection..." )
		PPCommon.pprint( "simpleBackup():  Garbage collection finished, #{PPCommon.gc.to_s} deleted." )
		date=PPCommon.newDatetime
		error=false
		PPCommon.makeBackupDirectory(backup[:BackupDestination]) unless (
			File.exist?(backup[:BackupDestination]) and
			File.directory?(backup[:BackupDestination])
		)
		dest_name=PPCommon.addSlash(backup[:BackupDestination]) + 'backup/' + backup[:BackupName]
		FileUtils.mkdir_p(dest_name) unless File.exist?(dest_name)
		PPCommon.pprint("simpleBackup():  Fatal error, conflict between backup name and existing file/dir in backup destination.", :fatal) unless File.directory?(dest_name)
		dest_name_date=PPCommon.addSlash(dest_name) + PPCommon.addSlash(date)
		FileUtils.mkdir_p(dest_name_date) unless File.exist?(dest_name_date)
		err_log=dest_name_date + 'err_log.txt'
		first_or_second=nil

		pp backup
		if PPCommon.containsBackups?(backup[:BackupDestination], backup[:BackupName]).class==TrueClass
			first_or_second=:first
			PPCommon.pprint('simpleBackup():  Not first time backing up, hardlinking to old backups to save space')
			PPCommon.mark(dest_name_date.gsub(' ', '\ '))
			#This isn't the first backup, you can hardlink to the other backups.
			`rsync -a  --link-dest=../last_backup --log-file=#{dest_name_date.gsub(' ','\ ')}rsync_log.txt #{PPCommon.stripSlash(backup[:BackupTarget]).gsub(' ','\ ')} #{dest_name_date.gsub(' ','\ ')} &>#{err_log.gsub(' ','\ ')}`
		else
			first_or_second=:second
			PPCommon.pprint('simpleBackup():  First time backing up.')
			PPCommon.mark(dest_name_date.gsub(' ', '\ '))
			#This is the first backup.
			`rsync -a --log-file=#{dest_name_date.gsub(' ','\ ')}rsync_log.txt #{PPCommon.stripSlash(backup[:BackupTarget]).gsub(' ','\ ')} #{dest_name_date.gsub(' ','\ ')} &>#{err_log.gsub(' ','\ ')}`
		end

		er= PPCommon.rsyncErr?( $?, err_log )
		#maybe a case on the return value of whatWasError?()

		unless er==false  #unless there aren't any, process the errors by asking the user.
			#FIXME This is probly where we'd put the code to store the user response for the long term
			keep_fail=true
			er.each_key {|key|
				if key==:FailedToOpen
					er[key].each {|file_that_failed|
						keep_fail=false if PPCommon.prompt("Rsync error:  #{key.to_s}  -  '#{file_that_failed.strip}' \nIgnore this error? (Do not count this as an error, update the last_backup symlink?)")==:yes
					}
				end
			}
			er=false if keep_fail==false
		end

		if er==false
			if first_or_second==:first
				File.unlink( PPCommon.addSlash(dest_name) + 'last_backup')
				File.symlink( dest_name_date, PPCommon.addSlash(dest_name) + 'last_backup' )
				#run the method to scan all of the backups for duplicates and hardlink them
				PPCommon.shrinkBackupDestination(backup)
			else
				File.symlink( dest_name_date, PPCommon.addSlash(dest_name) + 'last_backup' )
			end
			PPCommon.removeMark(dest_name_date.gsub(' ', '\ '))
		end
		PPCommon.pprint( "simpleBackup():  Done with abnormal existatus - rsync gave non-zero exitstatus!\n\t\tBackup was performed, but some files may not have been copies so last_backup still points to your most recent completed backup.\n" ) unless er==false
		PPCommon.pprint( 'simpleBackup():  Done.  Check the log and the backups for bugs and errors.' )
		
		dest_name_date
	end
end
