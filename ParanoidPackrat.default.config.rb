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

load 'lib/PPackratConfig.rb'

#This line sets a Global backup destination, which will be defaulted to in the event
#of no backup destination being specified on the per backup name basis.
#PPackratConfig.setBackupDestination "/mnt/sdg"

#Backup your home directory to /mnt/sdi/
#
#This will create a directory called 'backup' in /mnt/sdi if it does
#not yet exist, it will then create a directory named /mnt/sdi/backup/jeff's\ home/,
#so as to have backups accessibly by name, and will put your backups in there sorted by date.
#PPackratConfig.addName "jeff's home"
#PPackratConfig.setBackupTarget "jeff's home", "/home/jeff"
#PPackratConfig.setBackupDestinationOn "jeff's home", "/mnt/sdi"



#Backup critical documents in your Documents folder, excluding anything in the work_in_progress
#directory
#
#This will create a directory called 'backup' in /mnt/sdi if it does not yet exist,
#and will then create a directory called /mnt/sdi/backup/critical_docs/, the name of
#the config, and will store your backups in there sorted by date.
#PPackratConfig.addName "critical_docs"
#PPackratConfig.setBackupTarget "critical_docs", "/home/jeff/Documents/"
#PPackratConfig.setBackupExclusions "critical_docs", "/home/jeff/Documents/work_in_progress"
#PPackratConfig.setBackupDestinationOn "critical_docs", "/mnt/sdi"

#Backup your /etc/ldap/slapd.conf file
#
#This will create a directory called 'backup' in '/mnt/sdi' if it does not yet exist
#and will then create a directory called /mnt/sdi/backup/slapd , the name of the 
#config and will store a backup of the file in there within dated directories.
#PPackratConfig.addName 'slapd'
#PPackratConfig.setBackupTarget 'slapd', "/etc/ldap/slapd.conf"


#Backup your Downloads folder, set the global backup destination folder, and backup to that
#instead of setting a BackupDestination for this config specifically.
#
#This will create a directory called /mnt/sdg/backup if it does not yet exist,
#and will then create a directory called /mnt/sdg/backup/downloads_dir , and
#will put your backups in there sorted by date.  If there are other backups also
#using the global backup destination, they will be in the same /mnt/sdg/backup/
#directory but under the name of their config not under downloads_dir.
#PPackratConfig.setBackupDestination "/mnt/sdg"
#PPackratConfig.addName "downloads_dir"
#PPackratConfig.setBackupTarget "downloads_dir", "/home/users/Downloads"
