#!/bin/bash

if [ -e in-out ] ; then
    rm -fr in-out
fi

mkdir "in-out"

cd "in-out"
quadp setup slides --dest-dir=`pwd`/dest
cp -rf ../template/slides/{Contents.pm,src} ./slides/
if (cd slides && quadp render -a) > dump.txt 2>&1 ; then
    echo "Error! quadp render -a did not stop on a broken input." 1>&2
    exit 1
fi
if ! grep '^Quad-Pres Error:' dump.txt > /dev/null ; then
    echo "Could not find an error in the error file" 1>&2
    exit 1
fi
if [ -e dest/two.html ] ; then
    echo "Error! The faulty file was found in the directory." 1>&2
    exit 1
fi

echo "Stop on WML Error Test Passed"


