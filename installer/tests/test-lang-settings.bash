#!/bin/bash

if [ ! -e in-out ] ; then
    mkdir in-out
else
    rm -fr in-out/*
fi
cd "in-out"

# Check that the default 
t=1
test_dir=testlang$t 
quadp setup $test_dir --dest-dir=`pwd`/${test_dir}-output
cat > $test_dir/src/index.html.wml <<EOF
#include 'template.wml'

<p>
Hello world!
</p>

EOF
(cd $test_dir && quadp render -a)
output_file=$test_dir-output/index.html
if ! tidy -errors $output_file ; then
    echo "File does not validate!" 1>2 ; 
    exit 
fi
if ! perl ../verify-lang-settings.pl iso-8859-1 en-US < $output_file ; then
    echo "File has improper language encodings" 1>2 
    exit
fi

# TODO:
# Write a test setting the encoding and/or language to something else

exit 1

