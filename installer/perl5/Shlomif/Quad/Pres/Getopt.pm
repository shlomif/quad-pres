package Shlomif::Quad::Pres::Getopt;

# A wrapper around Getopt::Long::Parser that allows it to use a different
# array instead of @ARGV.
#
# It's a kludge, but it works.

require Getopt::Long '2.24';

sub new
{
    my $class = shift;
    my $self = {};

    bless $self, $class;

    $self->_initialize(@_);

    return $self;
}

sub _initialize
{
    my $self = shift;

    $self->{'getopt'} = Getopt::Long::Parser->new();

    my $args = shift;
    
    $self->{'args'} = $args;
    
    return 0;
}

sub get_getopt
{
    my $self = shift;

    return $self->{'getopt'};
}

sub configure
{
    my $self = shift;

    return $self->get_getopt()->configure(@_);
}

sub getoptions
{
    my $self = shift;

    my (@params) = (@_);

    my $getopt = $self->get_getopt();

    {
        local @ARGV = @{$self->{'args'}};
        return $getopt->getoptions(@params);
        @{$self->{'args'}} = @ARGV;
    }
}

1;

