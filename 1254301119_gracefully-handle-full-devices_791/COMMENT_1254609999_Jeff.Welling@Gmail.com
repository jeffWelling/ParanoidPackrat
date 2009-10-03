Commit a2426b14d9f8d5278bde020e7a3fccbc258d0e24 changes simpleBackup to return :fail if a backup could not be completed and room could not be made using gc and expireOldBackups.
