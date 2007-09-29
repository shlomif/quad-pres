#!/bin/sh

RPM=false
AUTOCONF=true

for OPT do
    if [ "$OPT" == "--rpm" ] ; then
        RPM=true
    elif [ "$OPT" == "--noac" ] ; then
        AUTOCONF=false
    else
        echo "Unknown option \"$OPT\"!"
        exit -1
    fi
done


if $AUTOCONF ; then
    ./autogen.sh
fi

./configure --prefix=$HOME/apps/test/quadpres && make dist

if $RPM ; then
    rpm -tb quad-pres-`cat ver.txt`.tar.gz
fi


