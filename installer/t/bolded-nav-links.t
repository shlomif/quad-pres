#!/usr/bin/perl

use strict;
use warnings;
no autodie;

use Test::More tests => 3;

use File::Path qw/ mkpath rmtree /;
use File::Copy::Recursive qw(dircopy fcopy);
use Cwd ();
use Path::Tiny qw/ path tempdir tempfile cwd /;

my $io_dir = "t/data/in-out-bolded-nav-links";
rmtree($io_dir);
mkpath($io_dir);

my $test_idx = 0;

sub perform_test
{
    my $orig_dir = Cwd::getcwd();

    chdir($io_dir);

    ++$test_idx;

    my $test_dir   = "testhtml$test_idx";
    my $output_dir = "$test_dir-output";

    my $pwd = Cwd::getcwd();

    # TEST
    ok( !system( "quadp", "setup", $test_dir, "--dest-dir=./rendered" ),
        "Running quadp setup was succesful." );

    my $tmpl_dir = "$orig_dir/t/lib/bolded-nav-links/template";

    fcopy( "$tmpl_dir/Contents.pm", "$test_dir/Contents.pm", );
    rmtree( ["$test_dir/src"] );
    dircopy( "$tmpl_dir/src", "$test_dir/src" );

    # TEST
    ok( !system("cd $test_dir && quadp render -a"), "quadp render -a", );

# For debug
# system("( echo 'Foobar'; ls -lR $test_dir ; for I in \$( find $test_dir -type f ) ; do echo \"===\$I===\" ; echo ; cat \$I ; done) 1>&2");

    # TEST
    like(
        scalar( path("$test_dir/rendered/finale/books.html")->slurp_raw() ),
        qr{<b>Next</b>}, "Next link was bolded",
    );

    chdir($orig_dir);
}

perform_test();
