module ParanoidPackrat
  class << self
    def run
      puts "Stuff goes here!"
      puts "silentMode = #{PPackratConfig.silentMode?.inspect}"
    end
  end
end
