#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Differences qw/ eq_or_diff /;
use File::Path        qw/ mkpath rmtree /;
use Path::Tiny        qw/ path tempdir tempfile /;
use lib './t/lib';
use QpTest::Obj ();

my $io_dir = path("t/data/in-out-html-correctness")->absolute;
rmtree($io_dir);
mkpath($io_dir);

# TEST:$num_themes=2;
my @themes = (qw(alon-altman-text shlomif-text));

my $test_idx = 0;

sub perform_test
{
    my $theme = shift;

    my $obj = QpTest::Obj->new(
        { io_dir => $io_dir, test_idx => ++$test_idx, theme => $theme } );
    $obj->cd;

    # TEST*$num_themes
    $obj->quadp_setup;
    $obj->set_theme;
    $obj->spew_index(<<'EOF');
#include 'template.wml'

<p>
Hello world!
</p>

EOF

    # TEST*$num_themes
    $obj->quadp_render;

    # TEST*$num_themes
    $obj->tidy_check;

    $obj->back;
}

foreach my $theme (@themes)
{
    perform_test($theme);
}
