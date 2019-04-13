#!/usr/bin/perl

use strict;
use warnings;

use autodie;

use Test::More tests => 1;

use File::Find::Object::Rule 0.0301;

{
    my $num_found = 0;

    my $subrule = File::Find::Object::Rule->new;

    my $rule = $subrule->or(
        $subrule->new->directory->name(qr/blib/)->prune->discard,
        $subrule->new->file()->name(qr/(?:xslt|t|rng|dtd|pm|xml|PL|pl)\z/)
    )->start("../..");

    while ( my $path = $rule->match() )
    {
        open my $fh, '<', $path;
    LINES:
        while ( my $line = <$fh> )
        {
            chomp($line);
            if ( $line =~ /[ \t]+\r?\z/ )
            {
                $num_found++;
                diag("Found trailing space in file '$path'");
                last LINES;
            }
        }
        close($fh);
    }

    # TEST
    is( $num_found, 0, "No trailing space found." );
}
