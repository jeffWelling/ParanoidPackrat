
create .incomplete_backup file in backupDest/backupName/datetime/ before performing a backup, and remove it
after the backup was performed successfully.  This way, incomplete backups can be searched for by looking for
any backupDest/backupName/datetime folder that still has the .incomplete_backup in it.
