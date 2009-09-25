module ParanoidPackrat
  class << self
    def run
      puts "Stuff goes here!"
      puts "silentMode = #{PPConfig.silentMode?.inspect}"
    end
  end
end
