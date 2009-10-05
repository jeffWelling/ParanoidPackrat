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
		return true if PPConfig.silentMode?
		puts str
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
	#	[ [filesystem, total_1K_blocks, used, available, capacity, mountpoint],
	#		[filesystem, ...] ]
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

	#takes a dir, and checks to see how much free space the drive that dir is on has.
	#debug_input is to allow an alternative source to PPCommon.df, generally intended for specs
	def self.getFreeSpace(dir, debug_input=nil)
		lump= debug_input.nil? ? (PPCommon.df) : (debug_input)
		dir=PPCommon.addSlash(dir)
		lump.each {|line|
			next if line[5].length > dir.length
			next unless dir.slice(0, line[5].length) == line[5]

			next_slash= dir.index('/', line[5].length)
			next if next_slash.nil?
			full_path=dir.slice(0, next_slash+1)

			return line[3] if dir.slice(0, dir.index('/', line[5].length) ) == line[5]
		}
		return lump[0][3]
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
    timestamp.sub!(/[-+]\d{2}:?\d{2}/,'') # strip off -07:00 modifier
    timestamp.sub!(/T/,'_')            # use '_' as a separator instead of 'T'
	end
	
	#symbolize text
	def self.symbolize text
    case text
      when /^$/           ; :empty
      when nil            ; :nil
      when /^(q|quit)$/i  ; :quit
      when /^(e|edit)$/i  ; :edit
      when /^(y|yes)$/i   ; :yes
      when /^(n|no)$/i    ; :no
      else                ; text.to_sym
    end
	end 

	#ask the user question, and return the response (with optional default)
	def self.ask question, default=nil
		print "\n#{question} "
		answer = $stdin.gets.strip.downcase
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
	#Using that example, it would create the dir "/mnt/backup/", it will return false if the
	#directory ("/mnt/backup/" in this case) exists and is not empty.  Otherwise, it will
	#return the path of the directory that was just created.
	def self.makeBackupDirectory(dir)
		raise "You idiot" unless dir.is_a? String
		return false unless Dir.glob("#{dir}/**/*").length.zero? # fail unless the directory is empty
		FileUtils.mkdir(addSlash(dir) + "backup/", :mode => 700)[0]
	end

	#initBackup creates a directory based on dir and name
	#return value is a string which contains the dir to work with
	#Intended to be used in PPIrb.rb in the backup methods
	def self.initBackup dir, name
		dest_name=PPCommon.addSlash(dir) + 'backup/' + name
		FileUtils.mkdir_p(dest_name) unless File.exist?(dest_name)
		PPCommon.pprint("simpleBackup():  Fatal error, conflict between backup name and existing file/dir in backup destination.", :fatal) unless File.directory?(dest_name)
		dest_name_date=PPCommon.addSlash(dest_name) + PPCommon.addSlash(PPCommon.newDatetime)
 		FileUtils.mkdir_p(dest_name_date) unless File.exist?(dest_name_date)
		PPCommon.mark(dest_name_date.gsub(' ', '\ '))
		dest_name_date.gsub(' ', '\ ')
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
				next if !backup_name.nil? and PPCommon.stripSlash(backup_name)!=l1    #If backup_name is specified, only check that directory	
				dest_backup_name=dest_backup + PPCommon.addSlash(l1)
				Dir.entries(dest_backup_name).each {|l2|
					next if l2[/^(\.|\.\.)$/]   #Skip '.' and '..'
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
		return false #until   "raise "File #{original_file} has changed since hashing!!" unless getFileSignature(original_file) == sig" Doesn't throw an error anymore.
=begin		its throwing this;    (Keep in mind, line numbers may become skewed as commits progress.

/var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/PPCommon.rb:271:in `shrinkBackupDestination': File /var/media/home/jeff/Documents/Projects//ParanoidPackrat/xaa has changed since hashing!! (RuntimeError)
        from /var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/PPCommon.rb:264:in `glob'
        from /var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/PPCommon.rb:264:in `shrinkBackupDestination'
        from /var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/PPIrb.rb:82:in `simpleBackup'
        from /var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/ParanoidPackrat.rb:6:in `run'
        from /var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/ParanoidPackrat.rb:5:in `each'
        from /var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/ParanoidPackrat.rb:5:in `run'
        from ./ParanoidPackrat.rb:35

=end
 
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
    PPCommon.pprint "Hardlinking #{new} to #{old}" # FIXME - use this until checks are coded
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

	#mark(dir) will mark the backup destination before performing a backup to assist in finding
	#incomplete backups later on. dir is expected to be the directory of backupDest/'backup'/backupName/datetime/
	#
	#See also: PPCommon.removeMark()
	def self.mark( dir )
		raise "You idiot!" unless dir.is_a? String
		`touch #{PPCommon.addSlash(dir) + '.incomplete_backup'}`
		true
	end

	#removeMark(dir) is intended to be used after a backup has been completed to remove the mark indicating an incomplete backup
	#dir must be the same as was applied to PPCommon.mark() before the backup was begun, obviously.
	def self.removeMark( dir )
		raise "You stupid individual!" unless dir.is_a? String
		File.delete(PPCommon.addSlash(dir) + '.incomplete_backup')
		true
	end

	#returns true is dir is marked as being an incomplete backup
	#else true
	def self.marked? dir, buffer=nil
		File.exist?(PPCommon.addSlash(dir) + '.incomplete_backup')
	end
	
	#Return a DateTime object representing 6 hours in the past
	def self.sixHoursAgo
		DateTime.parse(Time.new.-(60*60*6).to_s)
	end

	#gc will traverse every configured backupDestination folder, and will delete incomplete backups, identified by a mark that is 6 hours old or more.
	#optionally, setting buffer to nil will skip that 6 hour buffer, which is intended to make sure that if gc is run at the same time as a backup
	#is taking place, it doesn't delete the backup in progress.  Obviously this won't be a problem if you don't run it concurrently, and don't have it
	#set to run in cron.
	#FIXME I need to be set up to also check the global backup destination when it is set!
	def self.gc buffer=true
		num_deleted=0
		PPConfig.dumpConfig.each {|config|
			backup_path=PPCommon.addSlash(config[1][:BackupDestination]) + 'backup/' + PPCommon.addSlash(config[1][:BackupName])
			Dir.glob(backup_path + '*').each {|backup_instance|
				backup_path_incomplete=backup_instance + '/.incomplete_backup'
				datetime=backup_instance.gsub(backup_path, '')
				next unless PPCommon.datetimeFormat?(datetime)
				if buffer == true
					(FileUtils.rm_rf(backup_instance) and num_deleted+=1) if (PPCommon.marked?(backup_instance) and (DateTime.parse(File.mtime(backup_path_incomplete).to_s) > PPCommon.sixHoursAgo))
				else
					(FileUtils.rm_rf(backup_instance) and num_deleted+=1) if PPCommon.marked?(backup_instance)
				end
			}    #And the file was deleted, and jesus' boots were gone.
		}
		num_deleted
	end

	#takes a source, and a destination. destination is expected to be a backup directory.
	#It returns the estimated size the backup will take
	def self.willTakeUp? source, dest
		o=PPCommon.rsync( source, dest, '/dev/null', :dryrun)
		o.split("\n").each {|line|	
			return line[/\d+\sbytes$/][/\d+/] if line[/^total transferred file size/i]
		}
	end

	#simple wrapper for rsync
	#so that the rsync call is in one place
	def self.rsync(source, dest, err_log, dry_run=nil, human_readable=nil)
		`rsync -a  --link-dest=../last_backup#{dry_run.nil? ? (' ') : (' --dry-run')}#{human_readable.nil? ? (' '):(' -h')} --stats #{PPCommon.stripSlash(source).gsub(' ','\ ')} #{dest.gsub(' ','\ ')} 2>#{err_log.gsub(' ','\ ')}`	
	end

	#Expire old backups in backupDestination/backup/backupName, per the expiration policy defined in backup itself.
	def self.expireOldBackups(backup)
		#Do naughty, naughty things here.
	end

	#hasIncompleteBackups?() takes a backup Destination, and searches it for incomplete backups that are more than 6 hours old.
	#if buffer != true, than it will return true if there are any incomplete backups at all, regardless of when they were cretaed.
	#Be aware that setting buffer != true may return true if a backup is currently running.
	def self.hasIncompleteBackups?( backup_destination, buffer=true )
		Dir.glob(PPCommon.addSlash(backup_destination) + 'backup/*').each {|backup_name|
			Dir.glob(backup_name + '/*').each {|datetime|
				next unless PPCommon.datetimeFormat?(File.basename(datetime))
				if buffer.class==TrueClass
					return true if PPCommon.marked?(datetime) and (DateTime.parse(File.mtime(datetime).to_s) > PPCommon.sixHoursAgo)
				else 
					return true if PPCommon.marked?(datetime)
				end
			}
		}
		false
	end
end

