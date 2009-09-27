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
require 'pp'
require 'optparse'
require 'ostruct'

module PPConfig
	class <<self
		#checkYourConfig is called when an error is encountered reading the configuration. 
		def checkYourConfig
			puts "PPConfig:  Please check your configuration."
			@BadConfig=true
		end
		#This function is intended to be run AFTER the the configurations have been set
		#to make sure the configurations entered are sane.
		#if silent is not nil, then silent mode is activated for this function.
		def sanityCheck silent=nil
			@Configs.each {|config_name, config|
				puts "sanityCheck(): Warning, you have entered a blank configuration for '#{config_name}'!" if silent!=nil and config==nil
				unless config.nil?
		
					#Unless a global backup directory is set, make sure every config has it's own backup dir specified
					if @BackupDestinations.empty? 
						raise "No Global backup directory is set, and config '#{config_name}' does not have one set either!" if config[:BackupDestination].nil?
					end #of unless @BackupDestinations.empty?
				end #of unless config.nil?
			}
		end
		
		# 
    def set_default_options
      @options.silentMode = false
			@options.ignorePermissions = false
      configPath = File.expand_path(File.dirname(__FILE__) + '/../')
      @options.configFile = configPath + '/ParanoidPackrat.config.rb'
    end
    
    def parse_cli_args args
      options = @options
      parser = OptionParser.new do |p|
        p.banner = "Usage: ParanoidPackrat.rb [options]"
        # Add options
        p.on("-c","--config [FILE]","Specify a non-default config-file location.")    {|file| options.configFile = file }
        p.on("-s","--silent [BOOL]","Set silent mode - no output will be generated.  Intended for use with cron.") {|bool| options.silentMode = (bool !~ /(no|false)/) }
				p.on("-P","--ignorePermissions [BOOL]","Silently suppress read errors due to permissions.  Intended for use with cron, intended to be used with -s.") {|bool| options.ignorePermissions = (bool !~ /(yes|true)/) }
        p.on("-h","--help",            "Show this message")                           {       puts p ; exit }
        p.separator "Examples:"
        p.separator "\tParanoidPackrat --silent"
        p.separator "\tParanoidPackrat --config ~/ppconfig.rb"
      end
      parser.parse! args

      unless File.exists?(options.configFile)
        config = File.expand_path(options.configFile)
        raise "Config file required, can't find it at #{config}" unless File.exists? config
        raise "Config file #{config} is not readable" unless File.readable? config
        options.configFile = config
      end
#      load "#{options.configFile}"
      PPConfig.sanityCheck
    end

		#
		def ignorePermissions?
			@options.ignorePermissions
		end

		#return true if silentMode 
		def silentMode?
			@options.silentMode
		end

		#To be called once at the beginning of the config file
		def initialize
			@numOfConfigs||=0
			@Configs||={}
			@BadConfig||=false
			@BackupDestinations||=''
      @options = OpenStruct.new
      set_default_options
		end

		#setBackupDestination is a way of specifying a global backup Destination.
		#Global backup destinations will be used in leu of specifying a backup destination in the individual configs by name.
		#
		#backup_destination must exist and it must be a directory.
		def setBackupDestination backup_destination
			PPConfig.checkYourConfig unless File.exist?(backup_destination) and File.directory?(backup_destination)
			@BackupDestinations = backup_destination
			true
		end

		#addName creates a new blank configuration with the name you provided.
		#The config is then populated by referencing the name, and using the set* functions below.
		def addName configName
			if @Configs.include? configName
				puts "Config names must be unique"
				PPConfig.checkYourConfig
			end
			@Configs.merge!({ configName=>{:BackupName=>configName} }) and return false unless @Configs.include?(configName)
			false
		end
		#Number of configurations currently entered
		def length
			@Configs.length
		end
		#To look at the configuration
		def [] configName
			@Configs[configName]
		end
		#Dump configuration
		def dumpConfig
			@Configs
		end
		#name is the name of the config who's file your setting.
		#
		#thingToBackup is an absolute path to the file or directory that you want backed up
		def setBackupTarget name, thingToBackup
			unless @Configs.include? name
				puts "Must addName('#{name}') first"
				PPConfig.checkYourConfig
			end
			@Configs[name]||={}
			@Configs[name][:BackupTarget]=thingToBackup
			unless File.exist? thingToBackup
				puts "PPConfig:  File or directory does not exist? '#{thingToBackup}'"
				PPConfig.checkYourConfig
			end
			true
		end
		#name is the name of the config your setting.
		#
		#exclusion is a file or directory that you want to exclude from the backup target.
		#exclusion must be a subdirectory of the backup target.
		def setBackupExclusions name, exclusion
			unless @Configs.include?(name) and File.exist?(exclusion)
				puts "name not yet addName'd, or exclusion file/dir does not exist"
				PPConfig.checkYourConfig 
			end
			if exclusion.slice(0,@Configs[name][:BackupTarget].length)!=@Configs[name][:BackupTarget]
				puts "When using exclusions in this way, you must specify an exclusion which is a subset of the BackupTarget.\nSee Exclusions in the documentation"
				PPConfig.checkYourConfig
			end
			@Configs[name][:Exclusions]||=[]
			@Configs[name][:Exclusions] << exclusion unless @Configs[name][:Exclusions].include? exclusion
			true
		end
		#name is the name of the config your setting.
		#
		#guaranteed_num_of_backups is the guarunteed number of duplicates you want to keep across your drives.
		#guaranteed_num_of_backups must be an integer, or a string containing an integer
		#
		#<b>Note</b> that setting guaranteed_num_of_backups larger than the total number of backup drives your using
		#will issue a warning, and the maximum number of duplicates possible will be stored (one per device).
		def setDuplication name, guaranteed_num_of_backups
			unless @Configs.include?(name)
				puts "Must first addname('#{name}')"
				PPConfig.checkYourConfig
			end
			@Configs[name][:GuaranteedNumBackups]==guaranteed_num_of_backups.to_i
			true
		end
		#If setIsCritical is called with a name, and anything_but_nil as anything except nil, then
		#the backup specified by this name will be considered critical, and one copy will be kept
		#on every drive.
		def setIsCritical? name, anything_but_nil=nil
			unless @Configs.include?(name)
				puts "Must first addName('#{name}')"
				PPConfig.checkYourConfig
			end
			@Configs[name][:CriticalBackup]=true
			true
		end
		#setBackupDestinationOn sets the backup destination for a specific configuration as referenced
		#by name.  There can only be one backup destination per config when specified in this method.
		#subsequent calls simply overwrite the previous entry.
		def setBackupDestinationOn name, backup_destination
			unless @Configs.include?(name) and File.exist?(backup_destination) and File.directory?(backup_destination)
				puts "Must first addName('#{name}'), and '#{backup_destination}' must first exist and be a directory."
				PPConfig.checkYourConfig 
			end
			@Configs[name]||={}
			@Configs[name][:BackupDestination]||=''
			@Configs[name][:BackupDestination]= backup_destination
			true
		end
	end
	initialize
end
