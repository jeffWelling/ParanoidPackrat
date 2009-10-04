module ParanoidPackrat
  class << self
		#Run all backups
    def run
      puts "Performing a simple backup of each configured backup dir"
			PPConfig.dumpConfig.each {|config|
				PPIrb.simpleBackup(config[1])
			}
			PPConfig.dumpConfig.length
    end
  end
end
