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

#This module is intended to assist users while they are working with 
#ParanoidPackrat from IRB.  Basically, the executed ./ParanoidPackrat.rb
#file will interact with the IRB library, in a one on top of the other
#fashion.
module PPIrb
	#simpleBackup(backup) performs a simple backup.
	#backup is expected to be the hash from @Configs[name] .
	#It will;
	#	1. create a directory with the name of newDatetime() in the backup/name dir.
	#	2. perform an rsync -a --link-dest=../last_backup backupTarget backup/name/datetime/ .
	#	3. check entire backup/name dir recursively for duplicate files, and hardlink for single instance storage.
	#
	#In that order.
	def self.simpleBackup(backup)
		PPCommon.makeBackupDirectory(backup['BackupDestination'])
	end
end
