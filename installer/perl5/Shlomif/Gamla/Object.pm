package Shlomif::Gamla::Object;

use strict;

use Shlomif::Arad::Object;

use vars qw(@ISA);

@ISA=qw(Shlomif::Arad::Object);

sub initialize_analyze_args
{
    my $self = shift;
    my $spec = shift;

    my ($key, $value);

    while($key = shift)
    {
        while (my ($spec_key, $spec_callback) = each(%$spec))
        {
            if ($key =~ m/^-?${spec_key}$/)
            {
                $spec_callback->(shift());
            }
        }
    }

    return 0;
}

1;

