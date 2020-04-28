package QuadPres::Exception;

use 5.016;
use strict;
use warnings;

use parent 'QuadPres::Base';

sub _init
{
    return;
}

sub throw
{
    my $class = shift;
    my $args  = shift;

    my $exception = $class->new();
    $exception->{'text'} = $args->{text};

    die $exception;
}

sub text
{
    my $self = shift;

    return $self->{'text'};
}

package QuadPres::Exception::RenderFile;

use vars qw(@ISA);

@ISA = qw(QuadPres::Exception);

1;
