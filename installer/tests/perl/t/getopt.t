#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Shlomif::Quad::Pres::Getopt;

my @args = ("-w", "--option", "hello", "yes", "there", "-t");
my $parser = 
    Shlomif::Quad::Pres::Getopt->new(
        \@args,
    );

$parser->configure("require_order");

my $is_w = 0;
my $option_val = "";
$parser->getoptions(
    'w' => \$is_w,
    'option=s' => \$option_val,
);

# TEST
ok (!((! $is_w) || ($option_val ne "hello")),
    "Arguments were not processed correctly!");

# TEST
is (join("|", @args), "yes|there|-t",
    "Arguments left are incorrect! Arguments are:\n");
