module ParanoidPackrat
  class << self
		#Run all backups
    def run
      PPConfig.resetConfigs
      load PPConfig.configFile
      raise 'There is already an instance running.' unless PPCommon.starting==true
      begin
        PPCommon.pprint "Performing a simple backup of each configured backup dir"
        PPConfig.dumpConfig.each {|config|
          PPIrb.simpleBackup(config[1])
        }
        PPConfig.dumpConfig.length
      ensure
        PPCommon.exiting
      end
    end
  end
end
