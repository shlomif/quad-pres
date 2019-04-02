#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 64;

use File::Path qw/ rmtree /;
use File::Copy::Recursive qw(dircopy fcopy);
use lib "./t/lib";

use QpTest::Lang qw/ $io_dir perform_test /;

# TEST:$num_cfg=2*2*2*2;
# TEST*num_cfg*4

rmtree($io_dir);

my $test_idx = 0;

foreach my $lang1 ( "", "he-IL" )
{
    foreach my $char1 ( "", "utf-8" )
    {
        foreach my $lang2 ( "", "en-GB" )
        {
            foreach my $char2 ( "", "iso-8859-8" )
            {
                perform_test( ++$test_idx, $lang1, $char1, $lang2, $char2 );
            }
        }
    }
}
