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
        {
            'url' => "finale",
            'title' => "Finale",
            'subs' =>
            [
                {
                    'url' => "links.html",
                    'title' => "Links",
                },
                {
                    'url' => "books.html",
                    'title' => "Books",
                },
            ],
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
