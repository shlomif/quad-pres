package Contents;

use strict;

my $contents =
{
    'title' => "My Lecture Title",
    'subs' =>
    [
        {
            'url' => "two.html",
            'title' => "Child Node",
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
