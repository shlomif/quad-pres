#!/bin/bash

. common.bash

mkdir_if_not_exists "$devel_dir"
cd $devel_dir
mkdir_if_not_exists build
cd build
rm -fr *
svn export $root/tags/latest-devel/installer
src_dir=installer
if cmp $src_dir/ver.txt ../ver.txt ; then
    exit 0
fi
cp -f $src_dir/ver.txt ../ver.txt
cd $src_dir
./prepare_package.sh
cd ..
ver="$(cat ../ver.txt)"
rm -f ../${prog_name}-*.tar.gz
cp $src_dir/${prog_name}-$ver.tar.gz ../

