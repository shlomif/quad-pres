#!/usr/bin/perl -w

use strict;
use Shlomif::Quad::Pres::FS;

use vars qw($test_num @inputs);

@inputs = (undef, "", "     ");

my $filename = "test-for_chown.stub";

sub mydie
{
    my $error = shift;
    my $i = $inputs[$test_num];
    unlink($filename);
    die ("Error! $error test_num=$test_num input=" . (defined($i)?$i:"undef"));
}

#$SIG{__WARN__} = sub {
#    mydie("Warning was received");
#};

open O, ">$filename";
print O "";
close(O);

for($test_num = 0; $test_num < @inputs; $test_num++)
{
    my $fs = Shlomif::Quad::Pres::FS->new('group' => $inputs[$test_num]);
    
    if (exists($fs->{'gid'}))
    {
        mydie("gid was defined for an empty group");
    }

    $fs->my_chown($filename);
}

unlink($filename);

exit(0);


