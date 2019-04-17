#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use QuadPres::FS ();

my @inputs = ( undef, "", "     " );

my $filename = "test-for_chown.stub";

sub my_test
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $test_num = shift;
    my $fs       = shift;

    my $i = $inputs[$test_num];
    unlink($filename);

    # TEST*3
    ok(
        !exists( $fs->{gid} ),
        "Gid defined test_num=$test_num input=" . ( defined($i) ? $i : "undef" )
    );
}

#$SIG{__WARN__} = sub {
#    mydie("Warning was received");
#};

use IO::All qw / io /;
io->file($filename)->print("");

for my $test_num ( keys @inputs )
{
    my $fs = QuadPres::FS->new( 'group' => $inputs[$test_num] );

    my_test( $test_num, $fs );

    $fs->my_chown($filename);
}

unlink($filename);

exit(0);

