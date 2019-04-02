#!/usr/bin/perl

use strict;
use warnings;

use Cwd ();
use IO::All qw / io /;
use FindBin qw/ $Bin /;
use File::Spec ();
use File::Path qw / rmtree /;

my $SRC      = File::Spec->rel2abs("$Bin");
my $myprefix = Cwd::getcwd() . "/tests/installation";

my $build_dir = "FOO";

rmtree( [$build_dir] );
if (
    system(
"mkdir $build_dir && cd $build_dir && cmake -DCMAKE_INSTALL_PREFIX=$myprefix $SRC && make && make install"
    )
    )
{
    die "cmake Failed";
}

$ENV{PERL5LIB} //= '';
$ENV{PERL5LIB}              = "$myprefix/share/quad-pres/perl5:$ENV{PERL5LIB}";
$ENV{QUAD_PRES_NO_HOME_LIB} = 1;
$ENV{PATH}                  = "$myprefix/bin:$ENV{PATH}";

# system("bash");

my $test_idx = 1;

foreach my $lang1 ( "", "he-IL" )
{
    foreach my $char1 ( "", "utf-8" )
    {
        foreach my $lang2 ( "", "en-GB" )
        {
            foreach my $char2 ( "", "iso-8859-8" )
            {
                io->file("$SRC/tests/perl/t/lang-set-$test_idx.t")
                    ->print(<<"EOF");
use lib "./t/lib";

use QpTest::Lang qw/ perform_test /;
use Test::More tests => 4;
# TEST*4
perform_test( $test_idx, "$lang1", "$char1", "$lang2", "$char2" );
EOF
                ++$test_idx;
            }
        }
    }
}
exec(qq#cd $SRC/tests/perl/ && prove t/*.t#);
