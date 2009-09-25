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
	#if fatal is anything except nil, than an exception is raise with str instead
	#of printing the output.
	def self.pprint str, fatal=nil
		raise str unless fatal.nil?
#		return true if self.silentMode?
		puts str
	end

  #mktempdir(prefix = 'PP') will return a temp directory.
  #This directory is not yet, but should be auto-deleted on exit
  def self.mktempdir str = 'PP'
    str += '.XXXXXX' unless str =~ /X+$/
    `mktemp -td #{str}`.strip # Is there a better way?
  end
	
	#Add a slash to the end of str if there isn't already one there.
	def self.addSlash(str)
		str << "/" unless str[-1].chr == '/'
    str
	end

	#strip any trailing slashes from str if they exist
	def self.stripSlash(str)
    str.sub(/\/+$/,'')
	end

	#do a `df`, parse, return as array.  example return array below.
	#	[ ['/dev/sda1', filesystem, total_1K_blocks, used, available, capacity, mountpoint],
	#		['/dev/sdb1', ...] ]
	#the optional debug argument is for creating/using specs, if debug is provided it will be
	#used instead of calling out to `df`.
	def self.df debug=nil
		debug.nil? ? output=`df -P` : output=debug
		output=output.split("\n").reject {|l| !l[/^Filesystem/].nil? }  #Reject the first line of output, which is the columns.
		output.each_index {|i|
			filesystem= output[i][/^[^\s]+/]
			total_1k_blocks=''
			used=''
			available=''
			capacity=''
			mountpoint=''
			temp=''
			i2=0  #I cant believe I have to use an index, I MUST be tired
			output[i]=output[i].gsub(/^[^\s]+/, '')
			output[i][/(\s+\d+){3}\s+\d+%\s+\//].strip.chop.chop.chop.split(' ').each {|number|
				if i2==0
					total_1k_blocks=number			#Chef: "Hello children!"
					i2+=1												#Kids: "Hi Chef!"
				elsif i2==1										#Kids: "Chef, what would a priest want to put up our butts?"
					used=number									#Chef: "Goodbye!"
					i2+=1												#ROFL
				elsif i2==2
					available=number
					i2+=1
				elsif i2==3
					capacity=number
				end             			   #  << DAMN thats ugly
				temp=[total_1k_blocks, used, available, capacity]
			}
			temp << (output[i].gsub(/(\s+\d+){3}\s+\d+%\s+\//, '/'))
			output[i]= (temp.reverse << filesystem).reverse
		}
		output   #GODAMNYOUJESUS! GET OFF MY PORCH!
	end

	#returns true if str matches the date time format expected to be found in the backup destination folders
	#otherwise, returns false
	def self.datetimeFormat?(str)
    return true if str =~ /^[012][\d]{3}\-([0]\d|[1][0-2])\-([0-2]\d|[3][0-1])_([01]\d|[2][0-3]):([0-5]\d):([0-5]\d)$/
    false
	end

	#return a string to be used as the datetime part of the backup path name
	#the string is to be used   backup/backupname/HERE/...
	#Expected to be used once at the beginning of running a backup to use
	#in the backup path.
	def self.newDatetime
		timestamp = DateTime.now.to_s
    timestamp.sub!(/[-+]\d\d:\d\d/,'') # strip off -07:00 modifier
    timestamp.sub!(/T/,'_')            # use '_' as a separator instead of 'T'
	end
	
	#symbolize text
	def PPCommon.symbolize text
	 return :nil if text.nil?
		return :empty if text.empty?
		return :quit if text =~ /^(q|quit)$/i
		return :edit if text =~ /^(e|edit)$/i
		return :yes  if text =~ /^(y|yes)$/i
		return :no   if text =~ /^(n|no)$/i
		text.to_sym
	end 

	#ask the user question, and return the response (with optional default)
	def self.ask question, default=nil
		print "\n#{question} "
		answer = STDIN.gets.strip.downcase
		throw :quit if 'q' == answer
		return default if PPCommon.symbolize(answer)==:empty
		answer
	end

	#ask the user a question, return the symbolized response with optional default
	def self.ask_symbol question, default
		answer = PPCommon.symbolize PPCommon.ask(question)
		throw :quit if :quit == answer
		return default if :empty == answer
		answer
	end
	
	#ask the user question, loop until he selects a valid option.
	def self.prompt question, default = :yes, add_options = nil, delete_options = nil
		options = ([default] + [:yes,:no] + [add_options] + [:quit]).flatten.uniq
		if delete_options.class == Array
			delete_options.each {|del_option|
			options -= [del_option]
			}
		else
			options -= [delete_options]
		end
		option_string = options.collect {|x| x.to_s.capitalize}.join('/')
		answer = nil
		loop {
			answer = PPCommon.ask_symbol "#{question} (#{option_string.gsub('//', '/')}):", default
			(answer=default if answer==:nil) unless default.nil?
			break if options.member? answer
		}
		answer
	end

	#scanBackupDir(backup) will scan the dir/file specified in backup[:BackupTarget],
	#and will return an array with the full path of every file covered by
	#backup[:BackupTarget], excluding anything specified in backup[:Exclusions].
	#
	#<b>Note</b> backup is expected to be one of the configs from 
	#PPConfig.dumpConfig and PPConfig.sanityCheck is expected
	#to have been run already.
	def self.scanBackupDir backup
    path = if backup.respond_to? :keys
      backup[:BackupTarget]
    else
      backup.to_s
    end
		raise "You idiot - specify a path!" unless path
		raise "You idiot - #{path} doesn't exists!" unless File.exists?(path)
    collection = []
    Find.find(path) {|file| collection << file }
    return collection unless backup.respond_to?(:keys) && (exclusions = backup[:Exclusions])
    collection.reject {|file| [*exclusions].any? {|exclusion| file =~ exclusion } }
	end
	
	#makeBackupDirectory(dir) creates the backup directory structure to store the backups in.
	#dir is expected to be a directory, such as say, "/mnt" or "/mnt/".  
	#Using that example, it would create the dir "/mnt/backup/", it will return false unless
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
		return false unless counter==1
		FileUtils.mkdir( dir + "backup/", 700 )[0]
	end
	
	#This method is used to determine if a backup dir contains backups or not.
	#Basically, its used to tell if this if the first run backup, or if there are others
	#that it can use to help shrink the size of the backup.
	#
	#It will look for any directories underneath backup_dest, if they also contain a directory
	#which has the correct date time format, and there is a last_backup symlink pointing to a dir,
	#then it will return true that yes there is at least one existing backup meaning
	#this is not the first run.
	#Otherwise, if there are no directories underneath backup_dest which also contain a dir
	#with the name in the right date time format which also contains a last_backup symlink,
	#it will return false signaling that this is the first run.
	#If backup_dest does not exist, or there are other files in backup_dest, it will simply
	#return false.
	#
	#If backup_name is provided, that one backupDest/backupName dir will be checked for backups.
	#NOTE - all paths are expected to be full paths
	def self.containsBackups?(backup_dest, backup_name=nil)
		return false unless File.exist?(backup_dest) and File.directory?(backup_dest) and File.readable?(backup_dest)
		backup_dest=PPCommon.addSlash(backup_dest)
		has_a_backup=false
		last_backup=false
		files_in_backupdir=[]
=begin
		backupDest/* = l0
		backupDest/backup/* =l1
		backupDest/backup/backupName/* =l2
		backupDest/backup/backupName/datetime/* =l3
=end
		Dir.entries(backup_dest).each {|l0|
			next if l0[/^(\.|\.\.)$/]   #Skip '.' and '..'
			next unless l0[/^backup$/]
			dest_backup=backup_dest + 'backup/'
			Dir.entries(dest_backup).each {|l1|
				next if l1[/^(\.|\.\.)$/]   #Skip '.' and '..'
				next if !backup_name.nil? and backup_name!=l1    #If backup_name is specified, only check that directory	
				dest_backup_name=dest_backup + PPCommon.addSlash(l1)
				Dir.entries(dest_backup_name).each {|l2|
					next if l1[/^(\.|\.\.)$/]   #Skip '.' and '..'
					next unless PPCommon.datetimeFormat?(l2) or l2[/^last_backup$/]
					has_a_backup=true
					dest_backup_name_datetime=(dest_backup_name + l2) if l2[/^last_backup$/]
					last_backup=true if l2[/^last_backup$/] and File.symlink?(dest_backup_name_datetime)
				}
			}
		}
		return true if has_a_backup.class==TrueClass and last_backup.class==TrueClass
		return false
	end
	
	#shrinkBackupDestination(backup,wide) traverse through backups under backupDestination/backupName/ , hardlinking to save space
	#
	#By default, it will only traverse backup directories (backupDest/backupName/datetimes).  To get it to
	#scan every folder, set wide=true.  
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
	def self.shrinkBackupDestination(backup,wide=nil)
		raise "you idiot" unless backup.class==Hash
    sigs = getExistingFileSignatures
    Dir.glob("#{backup[:BackupTarget]}/**/*") {|new_file|
      sig = getFileSignature(new_file)
      unless sigs[sig]
        sigs[sig] = new_file
      else
        original_file = sigs[sig]
        next if original_file == new_file
        raise "File #{file} has changed since hashing!!" unless getFileSignature(original_file) == sig
        hardlinkFile(new_file, original_file)
      end
    }
    saveFileSignatures(sigs)
	end
	
  require 'yaml'
  #getExistingFileSignatures() reads the stored hashes in from a file
  #takes an optional filename, otherwise uses the default
  def self.getExistingFileSignatures(filename = nil)
    filename ||= '~/file_hashes.yaml'
    return {} unless File.exists?(File.expand_path(filename))
    YAML.load(File.read(File.expand_path(filename))) || {}
  end

  #saveFileSignatures(signatures) saves a list of signatures to a file
  #takes an optional filename, otherwise uses the default
  #returns number of bytes written
  def self.saveFileSignatures(signatures, filename = nil)
    filename ||= '~/file_hashes.yaml'
    File.open(File.expand_path(filename),'w') {|file| file.write signatures.to_yaml }
  end

  #getFileSignature(filename) hashes a file with sha1 and returns its signature
  def self.getFileSignature(filename)
    `sha1sum #{filename}`.split.first   #  Output looks like: 66b4e9c23697c5aa947b00f92c56ded95b0122e3  lib/PPCommon.rb
  end

  #hardLinkFile(new, old) makes 'new' a hardlink to 'old'
  #WARNING - deletes new without checking if hardlinking is possible
  def self.hardlinkFile(new,old)
    # check both share a filesystem (for hardlinking)
    # check both are identical
    # check not the same file
    #File.unlink new
    #File.link old, new
    puts "Hardlinking #{new} to #{old}" # FIXME - use this until checks are coded
    # check hardlink was made
    # restore original file otherwise
  end
     
	#whatWasError?  looks at p, which is expected to be a Process::Status object, and if its exit status was not zero
	#it will read the error log and try to collect the important lines to show the user.  Intended to be used in simpleBackup()
	#returns false if there was no error, otherwise will return a hash in the form of {:FailedToOpen=>[foo.txt,bar.txt]}
	#for example if there were two files, foo.txt and bar.txt which were not readable due to permission issues.
	#error_log is expected to be the full path to the error log in question.  The error log is expected to be the stderr output
	#from running rsync ... &>error_log, from simpleBackup().
	def self.rsyncErr?( p, error_log )
		return false if p.exitstatus==0
		results={:FailedToOpen=>[]}
		log=PPCommon.readFile(error_log)
		log.each {|log_line|
			case
				#In the folloring when tests, the .nil? and ! basically cancel each other out, but the reason they're used is to provide a boolean response
				#which is required for case/when (methinks)
				when (!log_line[/^.+?"/].nil? and !log_line[/": Permission denied \(13\)$/].nil?)
					#oh noes! This file, we can has no read access on it!
					results[:FailedToOpen] << log_line.gsub(/^.+?"/,'').gsub(/": Permission denied \(13\)$/,'')
			end
		}
		results
	end
	
	#readFile takes a filename, and optionally the maximum number of lines to read.
	#
	#returns the lines read as an array.
	def self.readFile file, max_lines=0
		counter=0
		read_lines=[]
		File.open(file, 'r') {|f|
			while (line= f.gets and counter<=max_lines)
				read_lines << line
				counter+=1 unless max_lines==0
			end
		}
		read_lines
	end
end

