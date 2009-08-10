#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;

use File::Path;
use File::Copy::Recursive qw(dircopy fcopy);
use Cwd;
use IO::All;
use HTML::Lint;

my $io_dir_proto = "t/data/in-out-credit";
my $io_dir = File::Spec->rel2abs($io_dir_proto);
rmtree ($io_dir);
mkpath ($io_dir);

# TEST:$num_themes=2;
my @themes = (qw(alon-altman-text shlomif-text));

# TEST:$num_credits=2;

my $test_idx = 0;

# TEST:$n=0;
sub perform_test
{
    my $theme = shift;
    my $credit = shift;

    my $orig_dir = Cwd::getcwd();

    chdir($io_dir);

    # diag("Test No. $test_idx : Theme=$theme credit=$credit");
    $test_idx++;

    my $test_dir = "testhtml-$test_idx";
    my $output_dir = "$test_dir-output";

    my $pwd = Cwd::getcwd();

    # TEST:$n++;
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

    my $tmpl_dir = "$orig_dir/t/lib/credit/template";

    fcopy("$tmpl_dir/Contents.pm", "$test_dir/Contents.pm",);
    foreach my $file (glob("$tmpl_dir/src/*.html.wml"))
    {
        fcopy($file, "$test_dir/src");
    }

    chdir($test_dir);

    if (!$credit)
    {
        my $fn = "template.wml";
        io->file($fn)->print(
            qq{<set-var qp_avoid_credit="yes" />\n\n}, 
            io->file($fn)->getlines(),
        );
    }
    
    # TEST:$n++;
    ok (!system("quadp", "render", "-a"),
        "quadp render -a ran successfully for theme '$theme'."
    );
    chdir($pwd);

    my $output_file = $output_dir."/index.html";
    my $contents = scalar(io->file($output_file)->slurp());
    my $re = qr{Made with Quad-Pres};

    # TEST:$n++
    if ($credit)
    {
        like(
            $contents,
            $re,
            "There is a credit notice"
        );
    }
    else
    {
        unlike(
            $contents,
            $re,
            "There is no credit notice."
        );
    }

    # TEST:$n++;
    unlike(
        scalar(io->file($output_dir."/two.html")->slurp),
        $re,
        "No credit notice at the non-root-file."
    );

    chdir($orig_dir);

    return;
}
# TEST:$num_asserts=$n;

# TEST*$num_themes*$num_credits*$num_asserts
foreach my $theme (@themes)
{
    foreach my $credit (0,1)
    {
        perform_test($theme, $credit);
    }
}

