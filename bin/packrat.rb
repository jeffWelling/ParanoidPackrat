#!/usr/bin/env ruby
# Executable for the ParanoidPackrat Rubygem

if File.exist?( File.join('lib', 'paranoidpackrat.rb') )
	$LOAD_PATH.unshift(
		File.join(
			File.dirname( __FILE__ ),
			'..',
			'lib'
		)
	)
end

require 'paranoidpackrat'

ParanoidPackrat::CLI.execute
