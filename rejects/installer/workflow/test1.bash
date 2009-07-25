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

check_files()
{
    local output_dir
    output_dir="$1"
    shift
    if [ \( \! -e $output_dir/index.html \) -o \( \! -e $output_dir/two.html \) ] ; then
        echo "The requested file do not exist in the output directory" 1>&2
        exit 1
    fi
}

perform_test()
{
let t++
echo "Test No. $t : Theme=$theme credit=$credit"

test_dir=testhtml$t
output_dir="$test_dir-output"
quadp setup $test_dir --dest-dir="`pwd`/$output_dir"

cp -R ../template/Contents.pm $test_dir
cp -R ../template/src/*.html.wml $test_dir/src

if ! (cd $test_dir && quadp render -a) ; then
    echo "quadp render -a Failed!" 1>&2
    exit 1
fi

check_files $test_dir-output

sed -i '/^upload_path=/s!=!='"`pwd`"'/upload!' $test_dir/quadpres.ini

if ! (cd $test_dir && quadp upload -a) ; then
    echo "quadp upload Failed!" 1>&2
    exit 1
fi


A="$(diff -u -r upload "$output_dir" | wc -l)"
if test "$A" -ne 0 ; then
    echo "Uploading failed!" 1>&2
    exit 1
fi

if ! (cd $test_dir && quadp render -a -hd) ; then
    echo "quadp Hard-Disk rendering Failed!" 1>&2
    exit 1
fi

check_files "$test_dir/hard-disk-html"
}
echo "Workflow Test"


perform_test


