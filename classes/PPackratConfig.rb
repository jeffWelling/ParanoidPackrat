class PPackratConfig
	def self.checkYourConfig
		puts "PPackratConfig:  Please check your configuration.  Config names must be unique."
		@@BadConfig=TRUE
	end 
	#To be called once at the beginning of the config file
	def initialize
		@@numOfConfigs||=0
		@@Configs||={}
		@@BadConfig||=FALSE
		@@BackupDestinations||=[]
	end

	#setBackupDestination is a way of specifying a global backup Destination.
	#global backup destinations will be used in leu of specifying a backup destination in the individual configs by name
	#backup_destination must exist and it must be a directory.
	def setBackupDestination backup_destination
		PPackrat.checkYourconfig unless File.exist?(backup_destination) and File.directory?(backup_destination)
		@@BackupDestinations << backup_destination unless @@BackupDestinations.include?(backup_destination)
		return TRUE
	end	

	#addName creates a new blank configuration with the name you provided
	#The config is then populated by referencing the name, and using the set* functions below.
	def addName configName
		@@Configs.merge!({ configName=>nil }) and return TRUE unless @@Configs.include?(configName)
		PPackratConfig.checkYourConfig
		return FALSE
	end
	#Number of configurations currently entered
	def length
		@@Configs.length
	end
	#To look at the configuration
	def [] configName
		@@Configs[configName]
	end
	#name is the name of the config who's file your setting
	#thingToBackup is an absolute path to the file or directory that you want backed up
	def setBackupTarget name, thingToBackup
		PPackratConfig.checkYourConfig unless @@Configs.include? name
		@@Configs[name]||={}
		@@Configs[name]['BackupTarget']=thingToBackup
		unless File.exist? thingToBackup
			puts "PPackratConfig:  File or directory does not exist? '#{thingToBackup}'"
			PPackratConfig.checkYourConfig
		end
		return TRUE
	end
	#name is the name of the config your setting
	#exclusion is a file or directory that you want to exclude from the backup target.
	#exclusion must be a subdirectory of the backup target.
	def setBackupExclusions name, exclusion
		PPackratConfig.checkYourConfig unless @@Configs.include?(name) and File.exist?(exclusion)
		(puts "When using exclusions in this way, you must specify an exclusion which is a subset of the BackupTarget.\nSee Exclusions in the documentation" and PPackratConfig.checkYourConfig) if exclusion.slice(0,@@Configs[name]['BackupTarget'].length)!=@@Configs[name]['BackupTarget']
		@@Configs[name]['Exclusions']||=[]
		@@Configs[name]['Exclusions'] << exclusion unless @@Configs[name]['Exclusions'].include? exclusion
		return TRUE
	end
	#name is the name of the config your setting
	#guaranteed_num_of_backups is the guarunteed number of duplicates you want to keep across your drives.
	#guaranteed_num_of_backups must be an integer, or a string containing an integer
	#Note that setting guaranteed_num_of_backups larger than the total number of backup drives your using
	#will issue a warning, and the maximum number of duplicates possible will be stored (one per device).
	def setDuplication name, guaranteed_num_of_backups
		PPackrat.checkYourConfig unless @@Configs.include?(name)
		@@Configs[name]['GuaranteedNumBackups']==guaranteed_num_of_backups.to_i
		return TRUE
	end
	#If setIsCritical is called with a name, and anything_but_nil as anything except nil, then
	#the backup specified by this name will be considered critical, and one copy will be kept
	#on every drive.
	def setIsCritical? name, anything_but_nil
		PPackrat.checkYourConfig unless @@Configs.include?(name) and anything_but_nil!=nil
		@@Configs[name]['CriticalBackup']=anything_but_nil
		return TRUE
	end
	#setBackupDestinationOn sets the backup destination for a specific configuration as referenced
	#by name.  There can only be one backup destination per config when specified in this method.
	#subsequent calls simply overwrite the previous entry.
	def setBackupDestinationOn name, backup_destination
		PPackrat.checkYourconfig unless @@Configs.include?(name) and File.exist?(backup_destination) and File.directory?(backup_destination)
		@@Configs[name]['BackupDestination']||=''
		@@Configs[name]['BackupDestination']= backup_destination
		return TRUE
	end
end
