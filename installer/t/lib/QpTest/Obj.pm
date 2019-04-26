package QpTest::Obj;

use strict;
use warnings;

use MooX qw/ late /;

use HTML::T5 ();
use IO::All qw/ io /;
use Cwd ();
use Test::More;

use Path::Tiny qw/ path tempdir tempfile cwd /;

has theme => (
    is  => 'rw',
    isa => 'Str',
);

has test_idx => (
    is  => 'rw',
    isa => 'Int',
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

1;

