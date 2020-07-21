#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Differences qw/ eq_or_diff /;
use File::Path qw/ rmtree /;
use File::Copy::Recursive qw(dircopy);
use Cwd ();

use Path::Tiny qw/ path tempdir tempfile cwd /;

use HTML::T5    ();
use XML::LibXML ();

sub calc_tidy
{
    return HTML::T5->new( { input_xml => 1, output_xhtml => 1, } );
}

sub p4n
{
    my $orig_dir = Cwd::getcwd();
    my $src_dir  = "t/data/p4n5/";
    my $s        = "t/data/p4n5-copy/";
    rmtree( [$s] );
    dircopy( $src_dir, $s );

    chdir($s);
    mkdir("rendered");

    # TEST
    ok( !system( "quadp", "render", "-a" ),
        "quadp render -a ran successfully for theme ''." );

    # TEST
    ok(
        !system( "quadp", "render_all_in_one_page", "--output-dir=all-in" ),
        "quadp render_all_in_one_page ran successfully for theme ''."
    );
    my $lint = calc_tidy;

    my $fn = "all-in/index.html";
    $lint->parse( $fn, path($fn)->slurp_utf8() );

    # TEST
    eq_or_diff( [ $lint->messages() ], [], "HTML is valid for all-in-one." );

    my $xml = XML::LibXML->new( load_ext_dtd => 1 );
    $xml->parse_file($fn);

    # TEST
    pass("XML validation for '$fn'.");
    chdir($orig_dir);
    rmtree( [$s] );
}

p4n();
