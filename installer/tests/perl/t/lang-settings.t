#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 64;

use File::Path;
use File::Copy::Recursive qw(dircopy fcopy);
use Cwd;
use IO::All;
use HTML::Lint;

# TEST:$num_cfg=2*2*2*2;

my $io_dir = "t/data/in-out-lang-settings";
rmtree ($io_dir);
mkpath ($io_dir);

my $test_idx = 0;

sub set_lang_settings
{
    my ($dir, $global_lang, $global_charset, $local_lang, $local_charset) = @_;

    my $add_header = sub
    {
        my $filename = shift;
        my $header = shift;

        open I, "<$filename";
        my $text = join("",<I>);
        close(I);

        open O, ">$filename";
        print O "$header\n$text";
        close(O);
    };

    my $total_lang = "en-US";
    my $total_charset = "iso-8859-1";

    my $get_header = sub
    {
        my $lang = shift;
        my $charset = shift;

        if ($lang)
        {
            $total_lang = $lang;
        }
        if ($charset)
        {
            $total_charset = $charset;
        }

        return "#include \"wml_helpers.wml\"\n" . 
                ($lang ? 
                    "<default-var \"qp_lang\" \"$lang\" />\n" : 
                    ""
                ) .
                ($charset ? 
                    "<default-var \"qp_charset\" \"$charset\" />\n" : 
                    ""
                );
    };

    if ($global_lang || $global_charset)
    {
        $add_header->(
            "$dir/template.wml", 
            $get_header->($global_lang, $global_charset),
            );
    }

    if ($local_lang || $local_charset)
    {
        $add_header->(
            "$dir/src/index.html.wml", 
            $get_header->($local_lang, $local_charset),
            );    
    }

    return ($total_charset, $total_lang);
}

sub verify_lang_settings
{
    my $charset = shift;
    my $lang = shift;
    my $filename = shift;

    my $text = io()->file($filename)->slurp();

    if (($text =~ /<\?xml version="1.0" encoding="$charset"\?>/) &&
        ($text =~ /<meta http-equiv="content-type" content="text\/html; charset=$charset"(\s+\/)?>/) &&
        ($text =~ /<html.*xml:lang="$lang" lang="$lang">/m))
    {
        return 0;
    }
    else
    {
        return "Encoding and/or lang of STDIN is incorrect.";
    }
}

sub perform_test
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $orig_dir = Cwd::getcwd();

    chdir($io_dir);

    $test_idx++;

    my @params = @ARGV;
    my (
        $global_to_set_lang,
        $global_to_set_charset,
        $local_to_set_lang,
        $local_to_set_charset
    ) = @params;

    my $test_dir = "test_lang$test_idx";

    my $pwd = Cwd::getcwd();

    # TEST*$num_cfg
    ok (!system("quadp", "setup", $test_dir,
            "--dest-dir=$pwd/$test_dir-output",
        ),
        "quadp setup for $test_idx was successful.",
    );

    io("$test_dir/src/index.html.wml")->print(<<'EOF');
#include 'template.wml'

<p>
Hello world!
</p>
EOF

    my @wanted = set_lang_settings($test_dir, @params);

    $pwd = Cwd::getcwd();
    chdir($test_dir);

    # TEST*$num_cfg
    ok (!system(qw(quadp render -a)),
        "quadp render -a was successful for test No. $test_idx"
    );
    chdir($pwd);

    my $output_file = "$test_dir-output/index.html";
    my $lint = HTML::Lint->new;

    $lint->parse_file($output_file);

    # TEST*$num_cfg
    ok (!scalar($lint->errors()),
        "HTML is valid for test No. '$test_idx'."
    );

    # TEST*$num_cfg
    is (verify_lang_settings(@wanted, $output_file),
        0,
        "File for '$test_idx' has proper language encodings",
    );
    
    chdir($orig_dir);
}

foreach my $lang1 ("","he-IL")
{
    foreach my $char1 ("", "utf-8")
    {
        foreach my $lang2 ("", "en-GB")
        {
            foreach my $char2 ("", "iso-8859-8")
            {
                perform_test($lang1,$char1,$lang2,$char2);
            }
        }
    }
}
