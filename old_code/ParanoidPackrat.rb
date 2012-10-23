#!/usr/bin/ruby
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

require 'prettyprint'

current_dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(current_dir + "/lib")

load 'ParanoidPackrat.rb'
load 'PPConfig.rb'
load 'PPCommon.rb'
load 'PPIrb.rb'

#Just load unless we are being executed from the CLI
if $0 == __FILE__ 
  #Load the options and config file from the command line
  PPConfig.parse_cli_args ARGV
  ParanoidPackrat.run
end

