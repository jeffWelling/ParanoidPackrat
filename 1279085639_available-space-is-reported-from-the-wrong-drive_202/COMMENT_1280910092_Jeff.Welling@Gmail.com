Could not replicate this bug.

irb(main):002:0> PPCommon.getFreeSpace "/mnt/sdi"
=> "732440736"
irb(main):003:0> PPCommon.getFreeSpace "/"
=> "94100"

Filesystem           1K-blocks      Used Available Use% Mounted on
/dev/sda1               264445    156692     94100  63% /
...
/dev/sdi1            732440928       192 732440736   1% /mnt/sdi
