#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use Test::More tests => 16;

use File::Path            qw/ mkpath rmtree /;
use File::Copy::Recursive qw(dircopy fcopy);
use Path::Tiny            qw/ path tempdir tempfile /;

use lib './t/lib';
use QpTest::Obj ();

my $io_dir = path("t/data/in-out-body-dir")->absolute;
rmtree($io_dir);
mkpath($io_dir);

# TEST:$num_themes=2;
my @themes = (qw(alon-altman-text shlomif-text));

# TEST:$num_dirs=2;
my @dirs = (qw(ltr rtl));

# TEST:$num_cfgs=$num_dirs*$num_themes;

my $test_idx = 0;

# TEST:$n=0;
sub perform_test
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $theme = shift;
    my $dir   = shift;

    my $obj = QpTest::Obj->new(
        { io_dir => $io_dir, test_idx => ++$test_idx, theme => $theme } );
    $obj->cd;

    # TEST:$n++;
    $obj->quadp_setup;
    $obj->set_theme;
    $obj->spew_index(<<"EOF");
<set-var qp_body_dir="$dir" />
#include 'template.wml'

<p>
Hello world!
</p>

EOF

    # TEST:$n++;
    $obj->quadp_render;

    # TEST:$n++;
    $obj->tidy_check;

    my $body_str = "<body>";
    if ( $dir eq "rtl" )
    {
        $body_str = q{<body dir="rtl">};
    }

    # TEST:$n++;
    like( $obj->slurp_index, qr{\Q$body_str\E},
        "output file contains the right body tag - " . $obj->test_idx,
    );
    $obj->back;

    return;
}

# TEST:$num_assertions=$n;

# TEST*$num_assertions*$num_cfgs
for my $theme (@themes)
{
    for my $dir (@dirs)
    {
        perform_test( $theme, $dir );
    }
}
