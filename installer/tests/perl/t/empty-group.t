#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use Shlomif::Quad::Pres::FS;

my ($test_num, @inputs);

@inputs = (undef, "", "     ");

my $filename = "test-for_chown.stub";

sub my_test
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $fs = shift;
    
    my $i = $inputs[$test_num];
    unlink($filename);

    # TEST*3
    ok (!exists($fs->{gid}),
        "Gid defined test_num=$test_num input=" . (defined($i)?$i:"undef"));
}

#$SIG{__WARN__} = sub {
#    mydie("Warning was received");
#};

open O, ">", $filename;
print O "";
close(O);

for($test_num = 0; $test_num < @inputs; $test_num++)
{
    my $fs = Shlomif::Quad::Pres::FS->new('group' => $inputs[$test_num]);
    
    my_test($fs);

    $fs->my_chown($filename);
}

unlink($filename);

exit(0);

