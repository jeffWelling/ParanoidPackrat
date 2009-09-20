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

#This is the collection of methods that are common to the ParanoidPackrat
#project.
module PPCommon
	#pprint is a function to help control output based on silent mode or not.
	#This is called from other internal methods to print output, which is then
	#only displayed if we are not in silent mode.
	def self.pprint str
		return TRUE if PPackratConfig.silentMode?
		puts str
	end
	#scanBackupDir(backup) will scan the dir/file specified in backup['BackupTarget'],
	#and will return an array with the full path of every file covered by
	#backup['BackupTarget'], excluding anything specified in backup['Exclusions'].
	#
	#<b>Note</b> backup is expected to be one of the configs from 
	#PPackratConfig.dumpConfig and PPackratConfig.sanityCheck is expected
	#to have been run already.
	def self.scanBackupDir backup
		
	end
end
