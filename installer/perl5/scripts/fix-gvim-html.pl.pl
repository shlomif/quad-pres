#!/usr/bin/perl -I{QP_MODULES_DIR}

use strict;

while (<>)
{
    s/<font color="(#[a-f0-9]{6})">/<span style="color : $1">/g;
    s!</font>!</span>!g;
    print $_;
}
