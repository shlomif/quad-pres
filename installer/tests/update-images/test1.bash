#!/bin/bash

# Make sure that the so-called "images" (non-WML files) are properly updated, 
# and not left as is if they alone were updated.

if [ ! -e in-out ] ; then
    mkdir in-out
else
    rm -fr in-out/*
fi
cd "in-out"

# Check that the default charset and lang are OK.
t=0

perform_test()
{
let t++

test_dir=testhtml$t
quadp setup $test_dir --dest-dir=./rendered

cp -R ../template/Contents.pm $test_dir
rm -fr "$test_dir/src"
cp -R ../template/src $test_dir/src

(cd $test_dir && quadp render -a)
# To be sure that the timestamp is non-identical
sleep 1
echo "this_should_exist = 1;" >> "$test_dir/src/test.js"
(cd $test_dir && quadp render -a)

output_file="$test_dir"/rendered/test.js

if ! grep -F "this_should_exist" "$output_file" > /dev/null ; then
    echo "Images are not necessarily updated" 1>&2
    exit 1
fi
}

perform_test

