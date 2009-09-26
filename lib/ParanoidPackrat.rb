module ParanoidPackrat
  class << self
		#Run all backups
    def run
			PPConfig.dumpConfig.each {|config|
				PPIrb.simpleBackup(config)
			}
    end
  end
end
