#!/usr/bin/perl -w

use strict;

my $charset = shift;
my $lang = shift;

my $filename = shift || "-";

open I, "<$filename" || die "Could not open file \"$filename\"!";
my $text = join("", <I>);
close(I);

if (($text =~ /<\?xml version="1.0" encoding="$charset"\?>/) &&
    ($text =~ /<meta http-equiv="content-type" content="text\/html; charset=$charset"(\s+\/)?>/) &&
    ($text =~ /<html.*xml:lang="$lang" lang="$lang">/m))
{
    exit 0;
}
else
{
    die "Encoding and/or lang of STDIN is incorrect."
}
