package QuadPres::Base;

use 5.016;
use strict;
use warnings;

use Class::XSAccessor;

sub new
{
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    # May throw an exception.
    $self->_init(@_);

    return $self;
}

sub mk_accessors
{
    my $package = shift;
    return $package->mk_acc_ref( [@_] );
}

sub mk_acc_ref
{
    my $package = shift;
    my $names   = shift;

    my $mapping = +{ map { $_ => $_ } @$names };

    eval <<"EOF";
package $package;

Class::XSAccessor->import(
    accessors => \$mapping,
);
EOF

}

1;

__END__


=encoding utf8

=head1 NAME

QuadPres::Base - base class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=head2 mk_accessors

=head2 mk_acc_ref

=head2

=cut

