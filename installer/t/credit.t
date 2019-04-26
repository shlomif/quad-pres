#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 16;
use File::Path qw/ mkpath rmtree /;
use File::Copy::Recursive qw(dircopy fcopy);
use Path::Tiny qw/ path tempdir tempfile cwd /;
use lib './t/lib';
use QpTest::Obj ();
use Cwd         ();

my $io_dir = path("t/data/in-out-credit")->absolute;
rmtree($io_dir);
mkpath($io_dir);

# TEST:$num_themes=2;
my @themes = (qw(alon-altman-text shlomif-text));

# TEST:$num_credits=2;

my $test_idx = 0;

# TEST:$n=0;
sub perform_test
{
    my $theme  = shift;
    my $credit = shift;

    # diag("Test No. $test_idx : Theme=$theme credit=$credit");
    $test_idx++;

    my $obj = QpTest::Obj->new(
        { io_dir => $io_dir, test_idx => $test_idx, theme => $theme } );
    $obj->cd;
    my $test_dir = $obj->test_dir;

    my $pwd = Cwd::getcwd();

    # TEST:$n++;
    ok(
        !system(
            "quadp", "setup", $test_dir, "--dest-dir=" . $obj->output_dir
        ),
        "Running quadp setup was succesful."
    );

    $obj->set_theme;
    my $tmpl_dir = $obj->orig_dir . "/t/lib/credit/template";

    fcopy( "$tmpl_dir/Contents.pm", "$test_dir/Contents.pm", );
    foreach my $file ( glob("$tmpl_dir/src/*.html.wml") )
    {
        fcopy( $file, "$test_dir/src" );
    }

    chdir($test_dir);

    if ( !$credit )
    {
        path("template.wml")->edit_raw(
            sub {
                $_ = qq{<set-var qp_avoid_credit="yes" />\n\n} . $_;
            }
        );
    }

    # TEST:$n++;
    ok( !system( "quadp", "render", "-a" ),
        "quadp render -a ran successfully for theme '$theme'." );
    chdir($pwd);

    my $contents = $obj->output_dir->child("index.html")->slurp_raw;
    my $re       = qr{Made with Quad-Pres};

    # TEST:$n++
    if ($credit)
    {
        like( $contents, $re, "There is a credit notice" );
    }
    else
    {
        unlike( $contents, $re, "There is no credit notice." );
    }

    # TEST:$n++;
    unlike( $obj->output_dir->child("two.html")->slurp,
        $re, "No credit notice at the non-root-file." );

    $obj->back;

    return;
}

# TEST:$num_asserts=$n;

# TEST*$num_themes*$num_credits*$num_asserts
foreach my $theme (@themes)
{
    foreach my $credit ( 0, 1 )
    {
        perform_test( $theme, $credit );
    }
}
