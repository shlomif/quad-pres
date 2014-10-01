#!/usr/bin/perl

use strict;
use warnings;

use Cwd ();
use IO::All qw / io /;

use File::Path qw / rmtree /;
my $myprefix = Cwd::getcwd() . "/tests/installation";

my $build_dir = "FOO";

rmtree ([$build_dir]);
if (system("mkdir $build_dir && cd $build_dir && cmake -DCMAKE_INSTALL_PREFIX=$myprefix ../../installer && make && make install"))
{
    die "cmake Failed";
}

$ENV{PERL5LIB} = "$myprefix/lib/perl5:$ENV{PERL5LIB}";
$ENV{QUAD_PRES_NO_HOME_LIB} = 1;
$ENV{PATH} = "$myprefix/bin:$ENV{PATH}";

# system("bash");

exec(
    qq#cd tests && cd ../../installer/tests/perl/ && prove t/*.t#
);
