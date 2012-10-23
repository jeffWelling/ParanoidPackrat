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
                sleep 1 #To assure that when we are being run automatically, it never tries to backup to the same place
		backup[:BackupDestination]=PPConfig[:globalDests] if backup[:BackupDestination].nil?
		PPCommon.pprint( "simpleBackup():  Performing simple backup on '#{backup[:BackupName]}' - '#{backup[:BackupTarget]}'  to  '#{backup[:BackupDestination].join("', '")}'")
		PPCommon.pprint( "simpleBackup():  Running garbage collection..." )
		PPCommon.pprint( "simpleBackup():  Garbage collection finished, #{PPCommon.gc.to_s} deleted." )
		date=PPCommon.newDatetime
		error=false
		dests=[]

		backup[:BackupDestination].each {|dest|
                        PPCommon.pprint("\n")
                        fail_happened=false
			PPCommon.makeBackupDirectory(dest) unless (
				File.exist?(dest) and
				File.directory?(dest)
			)

			dest_name=PPCommon.addSlash(dest) + 'backup/' + backup[:BackupName]
			dest_name_date=PPCommon.initBackup(dest, backup[:BackupName])
			err_log=dest_name_date + 'err_log.txt'
			first_or_second=nil

			if PPCommon.containsBackups?(dest, backup[:BackupName]).class==TrueClass
				first_or_second=:first
				PPCommon.pprint('simpleBackup():  Not first time backing up, hardlinking to old backups to save space')
			else
				first_or_second=:second
				PPCommon.pprint('simpleBackup():  First time backing up.')
			end

			# the /1024 is to account for nextBackupWillTake? returning bytes, and df returning 1K blocks, or kilobytes.
			PPCommon.pprint( "simpleBackup():  Calculating space..." )
			PPCommon.pprint( "simpleBackup():  Backup is estimated to take #{guess=(PPCommon.willTakeUp?(backup[:BackupTarget], dest_name_date).to_i / 1024 ) } Kilobytes.\nsimpleBackup():  Available space is  #{actual=PPCommon.getFreeSpace(dest_name_date)} Kilobytes." )
			unless (actual.to_i > guess.to_i)
				PPCommon.pprint("simpleBackup():  Omgpanic!   Available space is #{actual}, but backup is estimated to take #{guess}.")
				PPCommon.pprint("simpleBackup():  Attempting to free some space...\n")
				PPCommon.pprint("simpleBackup():  Expiring old backups...")
				PPCommon.pprint("simpleBackup():  #{PPCommon.expireOldBackups(backup) rescue 0} Expired...")
				unless actual.to_i > guess.to_i
                                        fail_happened=true
					PPCommon.pprint("simpleBackup(): FAIL - She just can't do it captain!")
				end
				#check for free space? only continue if theres space available.
			end
                        if fail_happened==true
                                PPCommon.pprint("simpleBackup():  Failed backing up #{backup[:BackupName]}, #{backup[:BackupTarget]} to #{dest}, see log output reasons why.")
                                next
                        end
			PPCommon.rsync( backup[:BackupTarget], dest_name_date, err_log)
			er= PPCommon.rsyncErr?( $?, err_log )
			#maybe a case on the return value of whatWasError?()

			unless er==false  #unless there aren't any, process the errors by asking the user.
				#FIXME This is probly where we'd put the code to store the user response for the long term
				keep_fail=true
				er.each_key {|key|
					if key==:FailedToOpen
						if PPConfig.ignorePermissions?
							keep_fail=false
							next
						end
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
				else
					File.symlink( dest_name_date, PPCommon.addSlash(dest_name) + 'last_backup' )
				end
				PPCommon.removeMark(dest_name_date.gsub(' ', '\ '))
			end
			PPCommon.pprint( "simpleBackup():  Done #{backup[:BackupName]}, '#{backup[:BackupTarget]}' to '#{dest}' with abnormal existatus - rsync gave non-zero exitstatus!\n\t\tBackup was performed, but some files may not have been copies so last_backup still points to your most recent completed backup.\n\n\n\n" ) unless er==false
			PPCommon.pprint( "simpleBackup():  Done #{backup[:BackupName]}, '#{backup[:BackupTarget]}' to '#{dest}'.  Check the log and the backups for bugs and errors.\n\n\n" )
			
			dests << dest_name_date
		}
		dests
	end

=begin
	#takes a backup hash, and tries to guess the next backup size using PPCommon.willTakeUp?()
	#NOTE that using only the dry-run method, as we currently do, does not accurately report how much space the backup will take
	#because it seems rsync doesn't account for the space that empty dirs take, 4k.  If you backup something with a lot of empty
	#directories, and you have barely made any changes, then this may return a very small amount for the next backup but with 
	#the size of directories it could easily amount to tens or hundreds of megabytes, in relation to the size of your backup target.
	#returns the estimated size in bytes
	def self.nextBackupWillTake? backup
		source=backup[:BackupTarget]
		destination=(PPCommon.addSlash(backup[:BackupDestination]) + 'backup/' + PPCommon.addSlash(backup[:BackupName]) + 'fake_destination')
		PPCommon.willTakeUp?(source, destination)
	end
=end

	#shrinkBackupDestination(backup,wide) scan backupDestination/backupName/ for duplicates, hardlinking to save space
	#
	#By default, it will only traverse backup directories (backupDest/backupName/datetimes).  To get it to
	#scan every folder, set wide=true. 
	#Regardless of the state of wide, it will not hardlink duplicate files inside the same backup
	#in order to preserve the convention of being able to restore from your backups exactly what you put in; If it were to hardlink
	#duplicates in the same backup then when you restored them you would either have to replace every hardlink'd file with a whole
	#copy of the originional or you would have to restore keeping the hardlinks as they are.  Restoring and keeping the hardlinks
	#as they are would only really be bad because of the potential of forgetting that you've hardlinked every duplicate and then
	#inadvertently changing all when you tried to change one, but a safe default has been chosen to avoid confusion and trouble.
	#
	#Be warned! This is a very dangerous operation if you forget that you've hardlinked
	#to files that are in backupDest/backupName that aren't your backups, and you use this option to hardlink to them, and then
	#you change them, YOU WILL BE CORRUPTING YOUR BACKUPS.  This is why wide=nil by default, but if you know you won't be
	#changing those files it could be useful to hardlink them to save a little bit of space.  
	#
	#Also note there is no undo for
	#this operation, if you run it once, that file is hardlinked and you will have to create a copy, unlink the file, and mv
	#the copy into place for every file thats not in a backupDest/backupName/datetimes dir to undo this operation!
	#
	#	NOTE THIS REQUIRES THAT YOUR BACKUPS ARE ATOMIC - NEVER EDIT YOUR BACKUPS
	def self.shrinkBackupDestination(backup,wide=nil,p=1)
	raise "you idiot!" unless backup.class==Hash
#	return true #Not yet ready for use, so just return true until it is.
#	sigs= PPCommon.getExistingFileSignatures
        sigs=[{},{}]
	list=[]
        PPCommon.pprint "shrinkBackupDestination():  Beginning.  This will take a very, _very_ long time."
=begin
#sigs format
sigs=[
{inode=>[[path1,path2,...], hash_of_file_at_inode]},
{path1=>[size,inode],
 path2=>[size,inode],
 ...}
]
=end
	backup[:BackupDestination].each {|backup_dest|
		Dir.glob("#{PPCommon.addSlash(backup_dest)}backup/#{backup[:BackupName]}/**/*") {|new_file|
                        next if File.directory?(new_file)
                        next if File.size(new_file) == 0     #Do not hardlink empty files!!!
			next if File.symlink?(new_file)==true and File.exist?(new_file)==false  #Don't try to follow the broken symlinks, they have herpes.
			#Collect list of files
			next if new_file.index("#{PPCommon.addSlash(backup_dest)}backup/#{backup[:BackupName]}/last_backup")==0  #Don't double process the last backup by traversing this symlink
			((list << new_file) and next) if sigs[1].has_key? new_file    #Next if this path is already in sigs
			inode=File.stat(new_file).ino
			size=File.size(new_file)
			sigs[1].merge!({ new_file=>[size,inode] })
			if sigs[0].has_key? inode
				sigs[0][inode][0] << new_file
			else
				sigs[0].merge!({ inode=>[[new_file],[]] })
			end
			next if new_file[/\/$/]
			list << new_file if new_file[/\/$/].nil?
		}
	}
	df=PPCommon.df
	$it=list
	list.each {|path1|
		next if path1[/\/$/]
		#Process list of files
		list.each {|path2|
			next if path1==path2 or PPCommon.getMountBase(path1.clone,df)!=PPCommon.getMountBase(path2.clone,df)  #skip if its itself, or if it's on different drives
			next if path2[/\/$/]     #Why this isn't filtered out by the line above, I have no fucking clue.  They exist DESPITE the fact that the line only adds them if theres no trailing '/'
			begin
				next unless sigs[1][path1][0] == sigs[1][path2][0]  #Next unless size==size
				next if sigs[1][path1][1] == sigs[1][path2][1]  #Next if inode==inode
				next if PPCommon.whichBackupInstance?(path1) == PPCommon.whichBackupInstance?(path2)   #Don't link files in the same backup
			rescue
				pp path1
				pp path2
				raise
			end
			skip=false
			sigs[0][ sigs[1][path2][1] ][0].each {|path_with_this_inode|
                                if path2.match(/Bang/i)
                                        pp path1
                                        pp path2
                                        pp path_with_this_inode
                                        pp sigs[0][ sigs[1][path1][1] ][0]
                                        pp sigs[0][ sigs[1][path2][1] ][0]
                                        pp sigs[1][path1][1]
                                        pp sigs[1][path2][1]
                                end

                                next if path2==path_with_this_inode
                                skip=true if path1==path_with_this_inode
#                                pp path_with_this_inode
                                #skip is hardlinking path1 to path2 would mean indirectly hardlinking two files within the same backup (this would contaiminate the backup)
                                skip=true if PPCommon.whichBackupInstance?(path2) == PPCommon.whichBackupInstance?(path_with_this_inode)
			}
                        PPCommon.pprint 'omg skipped?' if path2.match(/Bang/i) and skip==true
			next if skip==true

                        #If it hasn't been hashed yet  (hashing would store the value here)
                        begin
                        sigs[0][sigs[1][path1][1]][1]= PPCommon.getFileSignature(path1) if sigs[0][sigs[1][path1][1]][1].empty?   
                        sigs[0][sigs[1][path2][1]][1]= PPCommon.getFileSignature(path2) if sigs[0][sigs[1][path2][1]][1].empty?
                        next unless sigs[0][sigs[1][path1][1]][1] == sigs[0][sigs[1][path2][1]][1]  #Next unless the hashes match
                        rescue NoMethodError => e
                                puts "the fuck?"
                                pp path1
                                pp path2
                                pp sigs[0][sigs[1][path1][1]]
                                pp sigs[0][sigs[1][path2][1]]
                                PPCommon.prompt "the fuck?"
                                next
                        end

                        unless PPConfig.silentMode?.class==TrueClass
        			puts "Omg hardlinking"
                                pp sigs[0][sigs[1][path1][1]][0]
                                puts 'to'
                                pp sigs[0][sigs[1][path2][1]][0]
                                puts "\n"
                                PPCommon.prompt("continue?") unless p.nil?
                        end

                        #Is this even necessary?
                        if sigs[0][ sigs[1][path1][1] ][0].length >  1
                                if sigs[0][ sigs[1][path2][1] ][0].length >  1
                                        pp path1
                                        pp path2
                                        pp sigs[0][ sigs[1][path2][1] ][0]
                                        pp sigs[0][ sigs[1][path1][1] ][0]
                                        pp sigs[0][ sigs[1][path1][1] ][1]
                                        pp sigs[0][ sigs[1][path2][1] ][1]
                                        puts "EGADS!  panic,  both files have multiple hardlinks!  Waiting..."
                                        PPCommon.prompt("continue?") unless p.nil?

                                end
                                #Hardlink path2 to path1
=begin
                                sigs[0][ sigs[1][path2][1] ][0].each {|path2_path|
                                        sigs[0][ sigs[1][path1][1] ][0] << path2_path
                                        sigs[1][path2_path][1]= sigs[1][path1][1]
                                }
                                sigs[0].delete sigs[1][path2][1]
=end

                        elsif sigs[0][ sigs[1][path2][1] ][0].length >  1
                                #Hardlink path1 to path2
                                
#                                sigs[0][ sigs[1][path2][1] ][0] << path1
 #                               sigs[1][path1][1] = sigs[1][path2][1]
                        end


                        sigs[0][ sigs[1][path2][1] ][0].each {|path2_path|
                                begin
                                        File.move(path2_path, path2_path + '_')
                                        File.link(path1, path2_path)
                                        File.delete(path2_path + '_')
                                rescue
                                        File.move(path2_path + '_', path2_path)
                                end
                                sigs[0][ sigs[1][path1][1] ][0] << path2_path
                                sigs[1][path2_path][1]= sigs[1][path1][1]
                        }
                        sigs[0].delete sigs[1][path2][1]
#                        sleep 1
		}
		#Remove from the path from the list; we've compared it against every file, it doesn't need to be compared again.
		list.delete path1
	}

#	PPCommon.saveFileSignatures(sigs)
        list.length
=begin 
		raise "you idiot" unless backup.class==Hash
    sigs = getExistingFileSignatures
    Dir.glob("#{backup[:BackupTarget]}/**/*") {|new_file|
      sig = getFileSignature(new_file)
      unless sigs[sig]
        sigs[sig] = new_file
      else
        original_file = sigs[sig]
        next if original_file == new_file
        raise "File #{original_file} has changed since hashing!!" unless getFileSignature(original_file) == sig
        hardlinkFile(new_file, original_file)
      end
    }
    saveFileSignatures(sigs)
=end
	end
end
