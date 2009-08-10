#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use File::Path;
use File::Copy::Recursive qw(dircopy fcopy);
use Cwd;
use IO::All;
use HTML::Lint;

my $io_dir_proto = "t/data/in-out-gen-hd-html";
my $io_dir = File::Spec->rel2abs($io_dir_proto);
rmtree ($io_dir);
mkpath ($io_dir);


my $test_idx = 0;

# TEST:$n=0;
sub perform_test
{
    my $hd = shift;

    my $orig_dir = Cwd::getcwd();

    chdir($io_dir);

    $test_idx++;

    my $test_dir = "testhtml-$test_idx";
    my $output_dir = "$test_dir-output";

    my $pwd = Cwd::getcwd();

    # TEST:$n++;
    ok(
        !system(
        "quadp", "setup", $test_dir, "--dest-dir=$pwd/$output_dir"
        ),
        "Running quadp setup was succesful for hd '$hd'."
    );

    chdir($test_dir);
    
    # TEST:$n++;
    ok (!system("quadp", "render", "-a", ($hd ? ("-hd") : ())),
        "quadp render -a ran successfully for hd '$hd'."
    );

    # TEST:$n++;
    if ($hd)
    {
        ok(
            (-d "hard-disk-html"),
            "hard-disk-html was created as specified",
        );
    }
    else
    {
        ok(
            (! -d "hard-disk-html"),
            "hard-disk-html was not created as specified",
        );
    }

    chdir($orig_dir);

    return;
}

# TEST:$num_asserts=$n;

# TEST:$num_cfgs=2;
my @render_hd_configs = (0,1);

# TEST*$num_cfgs*$num_asserts
foreach my $hd (@render_hd_configs)
{
    perform_test($hd);
}

