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

#This is the collection of methods that are common to the ParanoidPackrat
#project.
module PPCommon
	#pprint is a function to help control output based on silent mode or not.
	#This is called from other internal methods to print output, which is then
	#only displayed if we are not in silent mode.
	def self.pprint str
		return TRUE if PPackratConfig.silentMode?
		puts str
	end
	
	#Add a slash to the end of name if there isn't already one there.
	def self.addSlash(name)
		name << "/" unless dir.reverse[0]==47  #FIXME Probly a better way of doing this than using the hardcoded value 47
		return name
	end

	#returns TRUE if str matches the date time format expected to be found in the backup destination folders
	#otherwise, returns FALSE
	def self.datetimeFormat?(str)
		return TRUE if !str[/^[012][\d]{3}\-([0]\d|[1][0-2])\-([0-2]\d|[3][0-4])$/].nil?
		return FALSE
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
	
	
end
