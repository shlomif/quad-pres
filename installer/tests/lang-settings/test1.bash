#!/bin/bash

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
echo "Test No. $t"
global_to_set_lang="$1"
shift
global_to_set_charset="$1"
shift
local_to_set_lang="$1"
shift
local_to_set_charset="$1"
shift
echo "Args: \"$global_to_set_lang\" \"$global_to_set_charset\" \"$local_to_set_lang\" \"$local_to_set_charset\""
    
test_dir=testlang$t
quadp setup $test_dir --dest-dir=`pwd`/${test_dir}-output
cat > $test_dir/src/index.html.wml <<EOF
#include 'template.wml'

<p>
Hello world!
</p>

EOF

wanted="$(perl ../set-lang-settings.pl "$test_dir" "$global_to_set_lang" "$global_to_set_charset" "$local_to_set_lang" "$local_to_set_charset")"

echo "Got \"$wanted\" as a result"

(cd $test_dir && quadp render -a)
output_file=$test_dir-output/index.html
if ! tidy -errors $output_file ; then
    echo "File does not validate!" 1>&2 
    exit 1
fi
if ! perl ../verify-lang-settings.pl $wanted < $output_file ; then
    echo "File has improper language encodings" 1>&2 
    exit 1
fi
}

for lang1 in "" "he-IL" ; do
    for char1 in "" "utf-8" ; do
        for lang2 in "" "en-GB" ; do
            for char2 in "" "iso-8859-8" ; do
                perform_test "$lang1" "$char1" "$lang2" "$char2"
            done
        done
    done
done

