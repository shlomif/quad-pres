#!/usr/bin/perl

use strict;
use warnings;

use Shlomif::Quad::Pres::CmdLine;

my $o = Shlomif::Quad::Pres::CmdLine->new();

$o->src_dir("Hello");
if ($o->src_dir() ne "Hello")
{
    die "src_dir() does not work.";
}
