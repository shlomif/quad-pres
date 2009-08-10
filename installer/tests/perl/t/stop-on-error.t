#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use File::Path;
use File::Copy::Recursive qw(dircopy fcopy);
use Cwd;
use IO::All;
use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );
use File::Spec;

my $io_dir_proto = "t/data/in-out-stop-on-error";
my $io_dir = File::Spec->rel2abs($io_dir_proto);
rmtree ($io_dir);
mkpath ($io_dir);

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

    chdir($io_dir);

    # TEST
    ok (!system("quadp", "setup", "slides", "--dest-dir=$io_dir/dest"),
        "Quadp setup is OK."
    );

    my $slides_dir = "$io_dir/slides";
    my $tmpl_dir = "$orig_dir/t/lib/stop-on-error/template/slides";

    fcopy("$tmpl_dir/Contents.pm", "$slides_dir/Contents.pm",);
    foreach my $file (glob("$tmpl_dir/src/*.html.wml"))
    {
        fcopy($file, "$slides_dir/src");
    }

    my $pwd = Cwd::getcwd();

    # TEST
    trap {
        chdir($slides_dir);
        ok(
            system("quadp", "render", "-a") != 0,
            "quadp render -a fails",
        );
    };

    chdir ($pwd);

    # TEST
    like ($trap->stderr(),
        qr{Quad-Pres Error:},
        "Find an error in the stderr",
    );

    # TEST
    ok (!(-e "dest/two.html"), 
        "Faulty file was not found in the directory"
    );

    chdir($orig_dir);
}

perform_test();
