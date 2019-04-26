#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;

use File::Path qw/ mkpath rmtree /;
use File::Copy::Recursive qw(dircopy fcopy);
use Cwd ();
use IO::All qw/ io /;
use HTML::T5 ();

use lib './t/lib';
use QpTest::Obj ();

my $io_dir = "t/data/in-out-body-dir";
rmtree($io_dir);
mkpath($io_dir);

# TEST:$num_themes=2;
my @themes = (qw(alon-altman-text shlomif-text));

# TEST:$num_dirs=2;
my @dirs = (qw(ltr rtl));

# TEST:$num_cfgs=$num_dirs*$num_themes;

my $test_idx = 0;

sub calc_tidy
{
    return HTML::T5->new( { input_xml => 1, output_xhtml => 1, } );
}

# TEST:$n=0;
sub perform_test
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $orig_dir = Cwd::getcwd();

    chdir($io_dir);

    $test_idx++;
    my $theme = shift;
    my $dir   = shift;

    my $obj = QpTest::Obj->new( { test_idx => $test_idx, theme => $theme } );
    my $test_dir = $obj->test_dir;
    my $pwd      = Cwd::getcwd();

    # TEST:$n++;
    ok(
        !system(
            "quadp",   "setup",
            $test_dir, "--dest-dir=$pwd/${test_dir}-output",
        ),
        "setup for test $test_idx is successful.",
    );

    $obj->set_theme;
    io()->file("$test_dir/src/index.html.wml")->print(<<"EOF");
<set-var qp_body_dir="$dir" />
#include 'template.wml'

<p>
Hello world!
</p>

EOF

    chdir($test_dir);

    # TEST:$n++;
    ok( !system(qw(quadp render -a)), "quadp render -a for test $test_idx", );
    chdir($pwd);

    my $output_file = "$test_dir-output/index.html";

    my $lint = calc_tidy;

    $lint->parse( "$test_dir-output/index.html",
        io->file("$test_dir-output/index.html")->utf8->all );

    # TEST:$n++;
    ok( !scalar( $lint->messages() ), "HTML is valid for test No. $test_idx." );

    my $body_str = "<body>";
    if ( $dir eq "rtl" )
    {
        $body_str = q{<body dir="rtl">};
    }

    # TEST:$n++;
    like(
        scalar( io()->file($output_file)->slurp ),
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
        perform_test( $theme, $dir );
    }
}
