#!/usr/bin/perl -w

use strict;

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

if ((! $is_w) || ($option_val ne "hello"))
{
    die "Arguments were not processed correctly!";
}

if (join("|", @args) ne "yes|there|-t")
{
    die "Arguments left are incorrect! Arguments are:\n" . 
        join("", map { "$_: $args[$_]\n" } (0 .. $#args));
}

