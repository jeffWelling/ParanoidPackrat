
simpleBackup():  Backup is estimated to take 3977592 Kilobytes.
simpleBackup():  Available space is  7171660 Kilobytes.
simpleBackup():  Done us-home/, '/home/us' to '/disks/backup/'.  Check the log and the backups for bugs and errors.

The available space reported seems to be from root directory:

Filesystem           1K-blocks      Used Available Use% Mounted on
/dev/sda1              8000068    922800   7077268  12% /
/dev/sda9             16000208   4072812  11927396  26% /home                   # the dir being backed up
/dev/sda10           904728992 295974928 608754064  33% /disks/user_data        # the pwd
/dev/sdc1            1953452376   7570512 1945881864   1% /disks/data2          # the backup target

