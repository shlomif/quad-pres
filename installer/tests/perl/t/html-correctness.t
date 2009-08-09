#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use File::Path;
use File::Copy::Recursive qw(dircopy fcopy);
use Cwd;
use IO::All;
use HTML::Lint;

my $io_dir = "t/data/html-correctness";
rmtree ($io_dir);
mkpath ($io_dir);

# TEST:$num_themes=2;
my @themes = (qw(alon-altman-text shlomif-text));

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
    my $theme = shift;

    my $orig_dir = Cwd::getcwd();

    chdir($io_dir);
    my $test_dir = "testhtml-$theme";
    my $output_dir = "$test_dir-output";

    my $pwd = Cwd::getcwd();

    # TEST*$num_themes
    ok(
        !system(
        "quadp", "setup", $test_dir, "--dest-dir=$pwd/$output_dir"
        ),
        "Running quadp setup was succesful."
    );

    my $wml_rc = io->file("$test_dir/.wmlrc");

    my $text = $wml_rc->slurp();
    $text =~ s{(-DTHEME=)[\w\-]+}{$1$theme};
    $wml_rc->print($text);

    io->file("$test_dir/src/index.html.wml")->print(<<'EOF');
#include 'template.wml'

<p>
Hello world!
</p>
    
EOF

    chdir($test_dir);
    # TEST*$num_themes
    ok (!system("quadp", "render", "-a"),
        "quadp render -a ran successfully for theme '$theme'."
    );
    chdir($pwd);

    my $lint = HTML::Lint->new;

    $lint->parse_file("$test_dir-output/index.html");

    # TEST*$num_themes
    ok (!scalar($lint->errors()),
        "HTML is valid for theme '$theme'."
    );

    chdir($orig_dir);
}

foreach my $theme (@themes)
{
    perform_test($theme);
}

