#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use File::Path;
use File::Copy::Recursive qw(dircopy fcopy);
use Cwd;
use IO::All;
use File::Spec;

my $io_dir_proto = "t/data/in-out-template-toolkit";
my $io_dir = File::Spec->rel2abs($io_dir_proto);
rmtree ($io_dir);
mkpath ($io_dir);

my $test_idx = 0;

sub check_files
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $output_dir = shift;

    return ok (((-e "$output_dir/index.html") && (-e "$output_dir/two.html")),
        "The requested files exist in the output directory"
    );
}

sub perform_test
{
    my $orig_dir = Cwd::getcwd();

    $test_idx++;

    chdir($io_dir);
    my $test_dir = "testhtml";
    my $output_dir = "$test_dir-output-fookorw";

    my $pwd = Cwd::getcwd();

    # TEST
    ok(
        !system(
        "quadp", "setup", $test_dir, "--dest-dir=./dest"
        ),
        "Running quadp setup was succesful."
    );

    my $ini_fn = "$test_dir/quadpres.ini";
    my @lines = io->file($ini_fn)->getlines();
    
    @lines = 
    (
        map 
        { 
            /\Aupload_path=/
                ? qq{tt_upload_path=[% ENV.mypath %]\n}
                : $_
        } 
        @lines
    );

    io->file($ini_fn)->print(@lines);

    mkpath($output_dir);
    local $ENV{'mypath'} = "$pwd/$output_dir";

    my $tmpl_dir = "$orig_dir/t/lib/template-toolkit/template";

    fcopy("$tmpl_dir/Contents.pm", "$test_dir/Contents.pm",);
    foreach my $file (glob("$tmpl_dir/src/*.html.wml"))
    {
        fcopy($file, "$test_dir/src");
    }

    # TEST
    ok(
        !system("cd $test_dir && quadp render -a"),
        "quadp render -a",
    );

    # TEST
    check_files("$test_dir/dest");

    # TEST
    ok (!system("cd $test_dir && quadp upload -a"),
        "quadp upload succeeded",
    );

    my $count = `diff -u -r "$test_dir/dest" "$output_dir" | wc -l`;

    $count =~ s{\D}{}g;

    # TEST
    is(
        $count,
        0,
        "Uploading failed.",
    );

    chdir($orig_dir);
}

perform_test();
