module ParanoidPackrat
  class << self
		#Run all backups
    def run
			PPConfig.dumpConfig.each {|config|
				PPIrb.simpleBackup(config[1])
			}
			PPConfig.dumpConfig.length
    end
  end
end
