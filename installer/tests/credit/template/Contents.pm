package Contents;

use strict;

my $contents =
{
    'title' => "My Lecture Title",
    'subs' =>
    [
        {
            'url' => "two.html",
            'title' => "Error",
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
