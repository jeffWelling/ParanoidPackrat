Replicated bug.
Key to replicate this bug is to set the backup destination to a symlink, which points to a location on another disk.  Doing this will trick PP into thinking that the available size on root is the size available in the backup destination folder which is in fact a symlink.
