package Contents;

use strict;

my $contents =
{
    'title' => "My Lecture Title",
    'subs' =>
    [
        {
            'url' => "one.html",
            'title' => "One - Good",
        },
        {
            'url' => "two.html",
            'title' => "Error",
        },
        {
            'url' => "three.html",
            'title' => "Three - Good",
        },
    ],
    'images' =>
    [
        'style.css',
    ],
};

sub get_contents
{
    return $contents;
}

1;
