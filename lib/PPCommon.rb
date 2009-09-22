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
require 'find'
require 'fileutils'
require 'date'

#This is the collection of methods that are common to the ParanoidPackrat
#project.
module PPCommon
	#pprint is a function to help control output based on silent mode or not.
	#This is called from other internal methods to print output, which is then
	#only displayed if we are not in silent mode.
	def self.pprint str
		return TRUE if self.silentMode?
		puts str
	end

  #mktempdir(prefix = 'PP') will return a temp directory.
  #This directory is not yet, but should be auto-deleted on exit
  def self.mktempdir str = 'PP'
    str += '.XXXXXX' unless str =~ /X+$/
    `mktemp -td #{str}`.strip # Is there a better way?
  end
	
	#Add a slash to the end of name if there isn't already one there.
	def self.addSlash(name)
		name << "/" unless name[-1].chr == '/'
		return name
	end

	#returns TRUE if str matches the date time format expected to be found in the backup destination folders
	#otherwise, returns FALSE
	def self.datetimeFormat?(str)
		return TRUE if !str[/^[012][\d]{3}\-([0]\d|[1][0-2])\-([0-2]\d|[3][0-1])_([01]\d|[2][0-3]):([0-5]\d):([0-5]\d)$/].nil?
		return FALSE
	end

	#return a string to be used as the datetime part of the backup path name
	#the string is to be used   backup/backupname/HERE/...
	#Expected to be used once at the beginning of running a backup to use
	#in the backup path.
	def self.newDatetime
		str=DateTime.now.to_s
		return "#{str[/^\d{4}\-\d{2}\-\d{2}/]}_#{str[/(\d{2}:){2}\d{2}/]}"
	end

	#scanBackupDir(backup) will scan the dir/file specified in backup[:BackupTarget],
	#and will return an array with the full path of every file covered by
	#backup[:BackupTarget], excluding anything specified in backup[:Exclusions].
	#
	#<b>Note</b> backup is expected to be one of the configs from 
	#PPackratConfig.dumpConfig and PPackratConfig.sanityCheck is expected
	#to have been run already.
	def self.scanBackupDir backup
		#simple sanity check
		raise "You idiot" unless backup.class==Hash
		collection=[]
		Find.find(backup[:BackupTarget]) {|path|
			collect=true
			if backup[:Exclusions].class==Array
				backup[:Exclusions].each {|exclusion|
					collect=false if path[Regexp.new(exclusion)]
				}
				collection << path unless collect==false
			else
				collection << path
			end
		}
		return collection
	end
	
	#makeBackupDirectory(dir) creates the backup directory structure to store the backups in.
	#dir is expected to be a directory, such as say, "/mnt" or "/mnt/".  
	#Using that example, it would create the dir "/mnt/backup/", it will return FALSE unless
	#directory ("/mnt/backup/" in this case) exists and is not empty.  Otherwise, it will
	#return the path of the directory that was just created.
	def self.makeBackupDirectory(dir)
		raise "You idiot" unless dir.class==String
		dir=PPCommon.addSlash(dir)
		#Make sure the directory is empty
		counter=0
		Find.find(dir) {|file|
			counter+=1
		}
		return FALSE unless counter==1
		FileUtils.mkdir( dir + "backup/", 700 )[0]
	end
	
	#This method is used to determine if a backup dir contains backups or not.
	#Basically, its used to tell if this if the first run backup, or if there are others
	#that it can use to help shrink the size of the backup.
	#
	#It will look for any directories underneath backup_dir, if they also contain a directory
	#which has the correct date time format, and there is a last_backup symlink pointing to a dir,
	#then it will return TRUE that yes there is at least one existing backup meaning
	#this is not the first run.
	#Otherwise, if there are no directories underneath backup_dir which also contain a dir
	#with the name in the right date time format which also contains a last_backup symlink,
	#it will return FALSE signaling that this is the first run.
	#If backup_dir does not exist, or there are other files in backup_dir, it will simply
	#return FALSE.
	#NOTE - backup_dir is expected to be a full path
	def self.containsBackups?(backup_dir)
		return FALSE unless File.exist?(backup_dir) and File.directory?(backup_dir) and File.readable?(backup_dir)
		backup_dir=PPCommon.addSlash(backup_dir)
		has_a_backup=true
		last_backup=true
		files_in_backupdir=[]
		Dir.entries(backup_dir).each{|f| files_in_backupdir << f }
		files_in_backupdir.each {|backup_name|
			next if backup_name=='.' or backup_name=='..'
			Dir.entries(backup_dir + backup_name).each{|backup_date|
				next unless PPCommon.datetimeFormat?(backup_date) or backup_date=='last_backup'
				has_a_backup=true if PPCommon.datetimeFormat?(backup_date)
				if backup_date=='last_backup'
					last_backup=true if File.symlink?(backup_dir + PPCommon.addSlash(backup_name) + 'last_backup' ) and File.directory?(backup_dir + PPCommon.addSlash(backup_name) + 'last_backup')

=begin
				Dir.entries(backup_dir + (PPCommon.addSlash(backup_name)) + backup_date).each {|last_backup|
					next unless last_backup=="last_backup"  #name of the link
					is_a_backup=true if File.symlink?(backup_dir + PPCommon.addSlash(backup_name) + PPCommon.addSlash(backup_date) + last_backup) and File.directory?(backup_dir + PPCommon.addSlash(backup_name) + PPCommon.addSlash(backup_date) + last_backup)
				}
=end
				end
			}
		}
		return TRUE if has_a_backup.class==TrueClass and last_backup.class==TrueClass
		return FALSE
	end
end
