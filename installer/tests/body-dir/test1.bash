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
echo "Test No. $t : Theme=$theme"

test_dir=testhtml$t
quadp setup $test_dir --dest-dir=`pwd`/${test_dir}-output
sed -i "s/-DTHEME=[-a-zA-Z_]\+/-DTHEME=${theme}/" $test_dir/.wmlrc

cat > $test_dir/src/index.html.wml <<EOF
#include 'template.wml'

<p>
Hello world!
</p>

EOF

(cd $test_dir && quadp render -a)
output_file=$test_dir-output/index.html
if ! tidy -errors $output_file ; then
    echo "File does not validate!" 1>&2 
    exit 
fi
}

for theme in $(cd ../../installation/share/quad-pres/wml/themes/ && ls) ; do
    perform_test "$theme"
done

