If checkout commit 7dd8c2b9f85916c804d26f5e2536b369f7965694  and run ./ParanoidPackrat.rb, and configure a backup in ParanoidPackrat.config.rb, you should get something similar to this.
/var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/PPCommon.rb:271:in `shrinkBackupDestination': File /var/media/home/jeff/Documents/Projects//ParanoidPackrat/xaa has changed since hashing!! (Run
        from /var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/PPCommon.rb:264:in `glob'
        from /var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/PPCommon.rb:264:in `shrinkBackupDestination'
        from /var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/PPIrb.rb:82:in `simpleBackup'
        from /var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/ParanoidPackrat.rb:6:in `run'
        from /var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/ParanoidPackrat.rb:5:in `each'
        from /var/media/home/jeff/Documents/Projects/ParanoidPackrat/lib/ParanoidPackrat.rb:5:in `run'
        from ./ParanoidPackrat.rb:35

