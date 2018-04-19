package Shlomif::Quad::Pres::Exception;

use strict;
use warnings;

use parent 'Shlomif::Quad::Pres::Base';

sub _init
{
    return;
}

sub throw
{
    my $class = shift;
    my $args = shift;

    my $exception = $class->new();
    $exception->{'text'} = $args->{text};

    die $exception;
}

sub text
{
    my $self = shift;

    return $self->{'text'};
}

package Shlomif::Quad::Pres::Exception::RenderFile;

use vars qw(@ISA);

@ISA=qw(Shlomif::Quad::Pres::Exception);

1;


