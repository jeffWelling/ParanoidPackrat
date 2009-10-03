simpleBackup() will now check that there is free space available, and will return :fail if an epicfail happened on account of not enough space.
