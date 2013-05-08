package Shlomif::Gamla::Object;

use strict;
use warnings;

use parent (qw( Shlomif::Arad::Object ));

sub initialize_analyze_args
{
    my $self = shift;
    my $spec = shift;

    my ($key, $value);

    while($key = shift)
    {
        while (my ($spec_key, $spec_callback) = each(%$spec))
        {
            if ($key =~ m/\A-?\Q${spec_key}\E\z/)
            {
                $spec_callback->(shift());
            }
        }
    }

    return 0;
}

1;

