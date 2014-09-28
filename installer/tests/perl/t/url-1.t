#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Shlomif::Quad::Pres::Url;

{
    my $u = Shlomif::Quad::Pres::Url->new(
        'foo.html',
    );

    my $other_u = Shlomif::Quad::Pres::Url->new(
        'bar.html',
    );

    # TEST
    is ($u->get_relative_url($other_u), './bar.html', "Test 1");
}
