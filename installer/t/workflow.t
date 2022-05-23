#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use File::Path qw/ mkpath rmtree /;
use List::Util qw/ all /;
use File::Copy::Recursive qw(dircopy fcopy);
use Cwd ();
use Path::Tiny qw/ path tempdir tempfile cwd /;

my $io_dir = "t/data/in-out-workflow";
rmtree($io_dir);
mkpath($io_dir);

sub check_files
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $output_dir = shift;

    return ok(
        (
            all
            {
                ( path("$output_dir/$_")->slurp_raw() =~
                        m#<link rel="stylesheet" href="style\.css"# )
            } qw/index.html two.html/
        ),
        "The requested files exist in the output directory"
    );
}

sub perform_test
{
    my $orig_dir = Cwd::getcwd();

    chdir($io_dir);
    my $test_dir   = "testhtml1";
    my $output_dir = "$test_dir-output";

    my $pwd = Cwd::getcwd();

    # TEST
    ok( !system( "quadp", "setup", $test_dir, "--dest-dir=$pwd/$output_dir" ),
        "Running quadp setup was succesful." );

    my $tmpl_dir = "$orig_dir/t/lib/workflow/template";

    fcopy( "$tmpl_dir/Contents.pm", "$test_dir/Contents.pm", );
    foreach my $file ( glob("$tmpl_dir/src/*.html.wml") )
    {
        fcopy( $file, "$test_dir/src" );
    }

    # TEST
    ok( !system("cd $test_dir && quadp render -a"), "quadp render -a", );

    # TEST
    check_files("$test_dir-output");

    path("$test_dir/quadpres.ini")->edit_lines_raw(
        sub {
            s{\Aupload_path=.*\Z}{upload_path=$pwd/upload};
        }
    );

    # TEST
    ok( !system("cd $test_dir && quadp upload -a"), "quapd upload succeeded", );

    my $count = `diff -u -r upload "$output_dir" | wc -l`;

    $count =~ s{\D}{}g;

    # TEST
    is( $count, 0, "Uploading failed.", );

    # TEST
    ok(
        !system("cd $test_dir && quadp render -a -hd"),
        "quadp Hard-Disk rendering succeeded."
    );

    # TEST
    check_files("$test_dir/hard-disk-html");

    chdir($orig_dir);
}

perform_test();
