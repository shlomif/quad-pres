#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Differences qw/ eq_or_diff /;
use File::Path qw/ mkpath rmtree /;
use Cwd ();
use IO::All qw/ io /;
use HTML::T5 ();
use Path::Tiny qw/ path tempdir tempfile cwd /;
use lib './t/lib';
use QpTest::Obj ();

sub calc_tidy
{
    return HTML::T5->new( { input_xml => 1, output_xhtml => 1, } );
}

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
    my $test_dir = $obj->test_dir;

    my $pwd = Cwd::getcwd();

    # TEST*$num_themes
    ok(
        !system(
            "quadp", "setup", $test_dir, "--dest-dir=" . $obj->output_dir
        ),
        "Running quadp setup was succesful."
    );
    $obj->set_theme;
    io->file("$test_dir/src/index.html.wml")->print(<<'EOF');
#include 'template.wml'

<p>
Hello world!
</p>

EOF

    chdir($test_dir);

    # TEST*$num_themes
    ok( !system( "quadp", "render", "-a" ),
        "quadp render -a ran successfully for theme '$theme'." );
    chdir($pwd);

    my $lint = calc_tidy;

    $lint->parse( "$test_dir-output/index.html",
        $obj->output_dir->child("index.html")->slurp_utf8 );

    # TEST*$num_themes
    ok( !scalar( $lint->messages() ), "HTML is valid for theme '$theme'." );
    $obj->back;
}

foreach my $theme (@themes)
{
    perform_test($theme);
}
