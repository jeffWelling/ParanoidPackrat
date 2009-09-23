
simpleBackup() Works, and its awesome and you guys are kickass and stuff, but it would be REALLY cool if, when there were files in the
backup target that you do not have permission to read (and thus backup), it did not make the script think the backup failed.

Currently, if there is a file in the backup target directory that you can't read, the backup fails (despite actually backing up every
file except the ones you don't have permission to read), meaning that last_backup is not updated to point to the new backup.
