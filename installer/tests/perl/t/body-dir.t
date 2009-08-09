#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;

use File::Path;
use File::Copy::Recursive qw(dircopy fcopy);
use Cwd;
use IO::All;
use HTML::Lint;

my $io_dir = "t/data/in-out-body-dir";
rmtree ($io_dir);
mkpath ($io_dir);

# TEST:$num_themes=2;
my @themes = (qw(alon-altman-text shlomif-text));

# TEST:$num_dirs=2;
my @dirs = (qw(ltr rtl));

# TEST:$num_cfgs=$num_dirs*$num_themes;


my $test_idx = 0;

# TEST:$n=0;
sub perform_test
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $orig_dir = Cwd::getcwd();

    chdir($io_dir);

    $test_idx++;
    my $theme = shift;
    my $dir = shift;

    my $test_dir = "testhtml$test_idx";

    my $pwd = Cwd::getcwd();

    # TEST:$n++;
    ok (!system(
            "quadp", "setup", $test_dir, "--dest-dir=$pwd/${test_dir}-output",
        ),
        "setup for test $test_idx is successful.",
    );


    my $wml_rc = io->file("$test_dir/.wmlrc");

    my $text = $wml_rc->slurp();
    $text =~ s{(-DTHEME=)[\w\-]+}{$1$theme};
    $wml_rc->print($text);

    io()->file("$test_dir/src/index.html.wml")->print(<<"EOF");
<set-var qp_body_dir="$dir" />
#include 'template.wml'

<p>
Hello world!
</p>

EOF

    chdir($test_dir);

    # TEST:$n++;
    ok(
        !system(qw(quadp render -a)),
        "quadp render -a for test $test_idx",
    );
    chdir($pwd);

    my $output_file="$test_dir-output/index.html";

    my $lint = HTML::Lint->new;


    $lint->parse_file("$test_dir-output/index.html");

    # TEST:$n++;
    ok (!scalar($lint->errors()),
        "HTML is valid for test No. $test_idx."
    );

    my $body_str="<body>";
    if ($dir eq "rtl")
    {
        $body_str = q{<body dir="rtl">};
    }
    
    # TEST:$n++;
    like(
        scalar(io()->file($output_file)->slurp),
        qr{\Q$body_str\E},
        "output file contains the right body tag - $test_idx.",
    );

    return;
}

# TEST:$num_assertions=$n;

# TEST*$num_assertions*$num_cfgs
for my $theme (@themes)
{
    for my $dir (@dirs)
    {
        perform_test($theme,$dir);
    }
}

