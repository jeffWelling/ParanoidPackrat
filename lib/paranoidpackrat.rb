#requires go here!

#Add the directory containing this file to the start of the load path
$:unshift( File.dirname(__FILE__) ) unless
	$:.include?( File.dirname(__FILE__) || $:.include?( File.expand_path( File.dirname(__FILE__) ) )

module ParanoidPackrat
	def self.open dir, options
	end
end
