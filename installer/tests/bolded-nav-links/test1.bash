#!/bin/bash

# Verify the HTML correctness for all the themes

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
output_file="$test_dir"/rendered/finale/books.html

if ! grep -F "<b>Next</b>" "$output_file" > /dev/null ; then
    echo "Next Link was not bolded" 1>&2
    exit 1
fi
}

perform_test

