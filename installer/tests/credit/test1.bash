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
local theme
theme="$1"
shift
local credit
credit="$1"
shift
echo "Test No. $t : Theme=$theme credit=$dir"

test_dir=testhtml$t
quadp setup $test_dir --dest-dir=`pwd`/${test_dir}-output
sed -i "s/-DTHEME=[-a-zA-Z_]\+/-DTHEME=${theme}/" $test_dir/.wmlrc

cp -R ../template/Contents.pm $test_dir
cp -R ../template/src/*.html.wml $test_dir/src

if ! $credit ; then
    sed -i '1 { i\
<set-var avoid_credit="yes" />\

}' template.wml
fi

(cd $test_dir && quadp render -a)
output_file=$test_dir-output/index.html
if ! tidy -errors $output_file ; then
    echo "File does not validate!" 1>&2 
    exit 1
fi

if $credit ; then
    if ! grep -F "Made with Quad-Pres" $output_file ; then
        echo "There is no credit notice!" 1>&2
        exit 1
    fi
else
    if grep -F "Made with Quad-Pres" $output_file ; then
        echo "There is a credit notice while there should not be!" 1>&2
        exit 1
    fi
fi

if grep -F "Made with Quad-Pres" $test_dir-output/two.html ; then
    echo "There is a credit notice while there should not be in the non-root file" 1>&2
    exit 1
fi
}

for theme in $(cd ../../installation/share/quad-pres/wml/themes/ && ls) ; do
    for credit in "true" "false" ; do
        perform_test "$theme" "$credit"
    done
done

