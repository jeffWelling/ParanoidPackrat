Crashes on line "raise "File #{original_file} has changed since hashing!!" unless getFileSignature(original_file) == sig"

Line 271 as of commit 7dd8c2b9f85916c804d26f5e2536b369f7965694
