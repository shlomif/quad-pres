#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

#TEST
use_ok(Shlomif::Quad::Pres);

{
my $contents1 = 
{
    'title' => "Title",
    'subs' =>
    [
        {
            'url' => "slide1.html",
            'title' => "First Slide",
            'num_stages' => 3,
        },
        {
            'url' => "slide2.html",
            'title' => "Second Slide",
        },
    ],
};

    {
        my $qp = Shlomif::Quad::Pres->new(
            $contents1,
            'doc_id' => 'slide1.html',
            'mode' => "server",
            'stage_idx' => 1,
        );
        ok($qp); # TEST

        my $next_url = $qp->get_next_url();
        ok($next_url eq "slide1.2.html"); # TEST

        $next_url = $qp->get_next_url('skip_slide' => 1);
        ok($next_url eq "slide2.html");   # TEST
        
    }
}
1;
