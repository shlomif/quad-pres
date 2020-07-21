#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use File::Path qw/ mkpath rmtree /;
use File::Copy::Recursive qw(dircopy fcopy);
use Cwd ();
use Path::Tiny qw/ path tempdir tempfile cwd /;

my $io_dir = "t/data/in-out-update-images";
rmtree($io_dir);
mkpath($io_dir);

my $test_idx = 0;

sub perform_test
{
    my $orig_dir = Cwd::getcwd();

    chdir($io_dir);

    $test_idx++;

    my $test_dir   = "testhtml$test_idx";
    my $output_dir = "$test_dir-output";

    my $pwd = Cwd::getcwd();

    # TEST
    ok( !system( "quadp", "setup", $test_dir, "--dest-dir=./rendered" ),
        "Running quadp setup was succesful." );

    my $tmpl_dir = "$orig_dir/t/lib/update-images/template";

    fcopy( "$tmpl_dir/Contents.pm", "$test_dir/Contents.pm", );
    rmtree("$test_dir/src");
    dircopy( "$tmpl_dir/src", "$test_dir/src" );

    # TEST
    ok( !system("cd $test_dir && quadp render -a"), "quadp render -a", );

    # To be sure that the timestamp is non-identical
    sleep(1);

    path("$test_dir/src/test.js")->append_raw("this_should_exist = 1;");

    # TEST
    ok( !system("cd $test_dir && quadp render -a"), "quadp render -a", );

    # TEST
    like(
        scalar( path("$test_dir/rendered/test.js")->slurp_raw ),
        qr{this_should_exist}, "Images are updated.",
    );

    chdir($orig_dir);
}

perform_test();
