#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use Shlomif::Quad::Pres::Url;

{
    my $u = Shlomif::Quad::Pres::Url->new( 'foo.html', );

    my $other_u = Shlomif::Quad::Pres::Url->new( 'bar.html', );

    # TEST
    is( $u->get_relative_url($other_u), 'bar.html', "Test 1" );
}

{
    my $u = Shlomif::Quad::Pres::Url->new( [ 'foo', 'bar', 'baz', ], 1 );

    my $other_u = Shlomif::Quad::Pres::Url->new( [ 'foo', 'yaml.html', ], 0 );

    # TEST
    is( $u->get_relative_url($other_u), '../../yaml.html', "Test 2" );
}
