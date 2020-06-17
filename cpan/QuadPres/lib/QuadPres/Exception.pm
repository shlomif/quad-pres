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

__END__

=encoding utf8

=head1 NAME

QuadPres::Exception - exception class

=head1 SYNOPSIS

    use QuadPres::Exception ();

    QuadPres::Exception->throw({text=>"error"});

=head1 METHODS

=head2 throw

=head2 text

Returns the text.

=cut
