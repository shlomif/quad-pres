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

sub quadp_setup
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $self = shift;

    return ok(
        !system(
            "quadp",         "setup",
            $self->test_dir, "--dest-dir=" . $self->output_dir
        ),
        "Running quadp setup was succesful."
    );
}

sub spew_index
{
    my $self = shift;

    return $self->test_dir->child( "src", "index.html.wml" )->spew_utf8(@_);
}

sub slurp_index
{
    my $self = shift;

    return $self->output_dir->child("index.html")->slurp_utf8;
}

sub quadp_render
{
    my $self = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    chdir( $self->test_dir );

    ok(
        !system(qw(quadp render -a)),
        "quadp render -a for test " . $self->test_idx,
    );
    chdir( $self->io_dir );
}

1;

