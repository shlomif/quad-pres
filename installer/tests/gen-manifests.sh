#!/bin/sh
# perl get-files-list.pl -d > MANIFEST-DIRS
perl get-files-list.pl -f > MANIFEST
echo MANIFEST >> MANIFEST
# echo MANIFEST-DIRS >> MANIFEST
