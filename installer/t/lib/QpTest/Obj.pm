package QpTest::Obj;

use strict;
use warnings;

use MooX qw/ late /;

use HTML::T5 ();
use IO::All qw/ io /;
use Cwd ();
use Test::More;

use Path::Tiny qw/ path tempdir tempfile cwd /;

has [ 'io_dir', '_pwd' ] => ( is => 'rw' );
has orig_dir => ( is => 'ro', default => sub { return cwd; } );
has theme    => (
    is  => 'rw',
    isa => 'Str',
);

has test_idx => (
    is  => 'rw',
    isa => 'Int',
);

has output_dir => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        return $self->io_dir->child( "testhtml" . $self->test_idx . '-output' );
    },
    lazy => 1,

    # other attributes
);
has test_dir => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        return path( "testhtml-" . $self->test_idx );
    },
    lazy => 1,

    # other attributes
);

sub cd
{
    my $self = shift;

    chdir( $self->io_dir );

    return;
}

sub set_theme
{
    my $self  = shift;
    my $theme = $self->theme;

    $self->test_dir->child(".wmlrc")->edit_raw(
        sub {
            s{(-DTHEME=)[\w\-]+}{$1$theme};
        }
    );

    #body ...

    return;
}

sub back
{
    my $self = shift;

    chdir( $self->orig_dir );

    return;
}

1;

