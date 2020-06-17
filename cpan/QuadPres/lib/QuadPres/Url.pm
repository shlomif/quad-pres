package QuadPres::Url;

use 5.016;
use strict;
use warnings;

use List::Util 1.34 qw( notall );
use Carp ();

use parent 'QuadPres::Base';
use Data::Dumper qw/ Dumper /;

__PACKAGE__->mk_acc_ref(
    [
        qw(
            is_dir
            mode
            url
            )
    ]
);

sub _init
{
    $Carp::RefArgFormatter = sub {
        Dumper( [ $_[0] ], );
    };
    my $self = shift;

    my $url = shift;

    if ( !defined($url) )
    {
        Carp::confess("URL passed undef.");
    }

    if ( ref($url) eq 'ARRAY' )
    {
        if ( notall { defined } @$url )
        {
            Carp::confess("URL passed FOOundef.");
        }
        $self->url( [@$url] );
    }
    else
    {
        $self->url( [ split( /\//, $url ) ] );
    }
    $self->is_dir( shift || 0 );
    $self->mode( shift   || 'server' );

    return 0;
}

sub get_url
{
    my $self = shift;

    return [ @{ $self->url } ];
}

sub get_relative_url
{
    my $base = shift;

    my $url = $base->_get_url_worker(@_);

    return ( ( $url eq "" ) ? "./" : $url );
}

sub _get_url_worker
{
    my $base             = shift;
    my $to               = shift;
    my $slash_terminated = shift;

    my $prefix = "";

    my @this_url  = @{ $base->get_url() };
    my @other_url = @{ $to->get_url() };

    my $ret;

    my @this_url_bak  = @this_url;
    my @other_url_bak = @other_url;

    while (scalar(@this_url)
        && scalar(@other_url)
        && ( $this_url[0] eq $other_url[0] ) )
    {
        shift(@this_url);
        shift(@other_url);
    }

    if ( ( !@this_url ) && ( !@other_url ) )
    {
        if ( ( !$base->is_dir() ) ne ( !$to->is_dir() ) )
        {
            Carp::confess("Two identical URLs with non-matching is_dir()'s");
        }
        if ( !$base->is_dir() )
        {
            if ( scalar(@this_url_bak) )
            {
                return $prefix . $this_url_bak[-1];
            }
            else
            {
                die "Root URL is not a directory";
            }
        }
    }

    if ( ( $base->mode eq "harddisk" ) && ( $to->is_dir() ) )
    {
        push @other_url, "index.html";
    }

    $ret = "";

    if ($slash_terminated)
    {
        if ( ( scalar(@this_url) == 0 ) && ( scalar(@other_url) == 0 ) )
        {
            $ret = $prefix;
        }
        else
        {
            if ( !$base->is_dir() )
            {
                pop(@this_url);
            }
            $ret .= join( "/", ( map { ".." } @this_url ), @other_url );
            if ( $to->is_dir() && ( $base->mode ne "harddisk" ) )
            {
                $ret .= "/";
            }
        }
    }
    else
    {
        $ret .= $prefix;

        my @components;
        push @components,
            ( ("..") x ( $base->is_dir ? @this_url : @this_url - 1 ) );
        push @components, @other_url;
        $ret .= join( "/", @components );
        if (   ( $to->is_dir() )
            && ( $base->mode ne "harddisk" )
            && scalar(@components) )
        {
            $ret .= "/";
        }
    }

    #if (($to->is_dir()) && (scalar(@other_url) || $slash_terminated))

    return $ret;
}

1;

=encoding utf8

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 $url->get_relative_url($other_url)

=head2 $url->get_url()

=head2 $url->mode()

=head2 $url->is_dir()

=head2 $url->url()

=cut
