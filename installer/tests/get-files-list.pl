#!/usr/bin/perl

use strict;
use warnings;

use File::Copy;
use String::ShellQuote;

my $files_or_dirs = shift || "-f";

$files_or_dirs = ($files_or_dirs eq "-f");

my $source_dir = shell_quote(shift || ".");

my @lines = `svn ls -R $source_dir`;

my (@dirs, @files);

print
    grep
    { my $f = $_; chomp($f); $files_or_dirs ? (-f $f) : (-d $f); }
    sort
    { $a cmp $b }
    @lines
    ;
