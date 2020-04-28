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
