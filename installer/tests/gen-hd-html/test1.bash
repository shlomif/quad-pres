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

error()
{
    echo "$1" 1>&2
}

perform_test()
{
let t++
local hd
hd="$1"
shift

echo "Test No. $t : hd=$hd"

test_dir="testhtml$t"
quadp setup $test_dir --dest-dir=`pwd`/${test_dir}-output

cat > $test_dir/src/index.html.wml <<EOF
<set-var qp_body_dir="$dir" />
#include 'template.wml'

<p>
Hello world!
</p>

EOF

if $hd ; then
    params=" -hd "
else
    params=""
fi

(cd $test_dir && quadp render -a $params)
if $hd ; then
    if ! test -d $test_dir/hard-disk-html ; then
        error "hard-disk-html was not created while specified to be"
        exit 1
    fi
else
    if test -d $test_dir/hard-disk-html ; then
        error "hard-disk-html was created while note specified to be"
        exit 1
    fi
fi
}

for hd in true false ; do
    perform_test "$hd"
done

