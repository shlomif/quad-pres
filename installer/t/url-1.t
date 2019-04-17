#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use QuadPres::Url ();

{
    my $u = QuadPres::Url->new( 'foo.html', );

    my $other_u = QuadPres::Url->new( 'bar.html', );

    # TEST
    is( $u->get_relative_url($other_u), 'bar.html', "Test 1" );
}

{
    my $u = QuadPres::Url->new( [ 'foo', 'bar', 'baz', ], 1 );

    my $other_u = QuadPres::Url->new( [ 'foo', 'yaml.html', ], 0 );

    # TEST
    is( $u->get_relative_url($other_u), '../../yaml.html', "Test 2" );
}
