#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Shlomif::Quad::Pres::CmdLine;

{
    my $o = Shlomif::Quad::Pres::CmdLine->new('cmd_line' => ["render", "-a"]);

    $o->src_dir("Hello");

    # TEST
    is ($o->src_dir(), "Hello", "src_dir accessor works.")
}
