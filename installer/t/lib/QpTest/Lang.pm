package QpTest::Lang;

use strict;
use warnings;

use parent 'Exporter';

our @EXPORT_OK = qw/ $io_dir perform_test /;

use HTML::T5 ();
use IO::All qw/ io /;
use Cwd ();
use Test::More;
use Path::Tiny qw/ path tempdir tempfile cwd /;
use QpTest::Obj ();

our $io_dir = path("t/data/in-out-lang-settings")->absolute;

sub verify_lang_settings
{
    my $charset = shift;
    my $lang    = shift;
    my $text    = shift;

    if (   ( $text =~ /<\?xml version="1.0" encoding="$charset"\?>/ )
        && ( $text =~ /<meta charset="\Q$charset\E"(\s+\/)?>/ )
        && ( $text =~ /<html.*xml:lang="$lang" lang="$lang">/m ) )
    {
        return 0;
    }
    else
    {
        return "Encoding and/or lang of STDIN is incorrect.";
    }
}

sub set_lang_settings
{
    my ( $dir, $global_lang, $global_charset, $local_lang, $local_charset ) =
        @_;

    my $add_header = sub {
        my $filename = shift;
        my $header   = shift;
        io->file($filename)->print( $header . io->file($filename)->all );
    };

    my $total_lang    = "en-US";
    my $total_charset = "iso-8859-1";

    my $get_header = sub {
        my $lang    = shift;
        my $charset = shift;

        if ($lang)
        {
            $total_lang = $lang;
        }
        if ($charset)
        {
            $total_charset = $charset;
        }

        return "#include \"wml_helpers.wml\"\n"
            . (
            $lang ? "<default-var \"qp_lang\" \"$lang\" />\n"
            : ""
            )
            . (
            $charset ? "<default-var \"qp_charset\" \"$charset\" />\n"
            : ""
            );
    };

    if ( $global_lang || $global_charset )
    {
        $add_header->(
            "$dir/template.wml", $get_header->( $global_lang, $global_charset ),
        );
    }

    if ( $local_lang || $local_charset )
    {
        $add_header->(
            "$dir/src/index.html.wml",
            $get_header->( $local_lang, $local_charset ),
        );
    }

    return ( $total_charset, $total_lang );
}

sub calc_tidy
{
    return HTML::T5->new( { input_xml => 1, output_xhtml => 1, } );
}

sub perform_test
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @params = @_;
    my (
        $test_idx,          $global_to_set_lang, $global_to_set_charset,
        $local_to_set_lang, $local_to_set_charset
    ) = @params;

    my $obj = QpTest::Obj->new(
        { io_dir => $io_dir, test_idx => $test_idx, theme => 't' } );
    $io_dir->mkpath;
    $obj->cd;
    $obj->test_dir->remove_tree;

    $obj->quadp_setup;
    $obj->spew_index(<<'EOF');
#include 'template.wml'

<p>
Hello world!
</p>
EOF

    my @wanted = set_lang_settings( $obj->test_dir, @params );

    $obj->quadp_render;
    my $lint = calc_tidy;

    $lint->parse( "output/index.html", $obj->slurp_index, );

    ok( !scalar( $lint->messages() ),
        "HTML is valid for test No. '$test_idx'." );

    is(
        verify_lang_settings( @wanted, $obj->slurp_index ),
        0, "File for '$test_idx' has proper language encodings",
    );

    $obj->back;
}

1;

