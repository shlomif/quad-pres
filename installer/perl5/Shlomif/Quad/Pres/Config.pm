package Shlomif::Quad::Pres::Config;

use strict;

use Shlomif::Gamla::Object;

use vars qw(@ISA);

@ISA=qw(Shlomif::Gamla::Object);

use Config::IniFiles;

sub initialize
{
    my $self = shift;

    my $base_path = ".";

    $self->initialize_analyze_args(
        {
            '[Pp]ath' => sub { my $new_path = shift; $base_path = $new_path; }
        },
        @_
    );

    $self->{'base_path'} = $base_path;

    my $cfg = 
        Config::IniFiles->new( 
            -file => "$base_path/quadpres.ini" 
        );

    if (!defined($cfg))
    {
        die "Could not open the configuration file!";
    }

    $self->{'cfg'} = $cfg;
    
    return 0;
}

sub get_server_dest_dir
{
    my $self = shift;

    return $self->{'cfg'}->val("quadpres", "server_dest_dir");
}

sub get_setgid_group
{
    my $self = shift;

    return $self->{'cfg'}->val("quadpres", "setgid_group");
}

sub get_rsync_upload_path
{
    my $self = shift;

    return $self->{'cfg'}->val("rsync", "upload_path");
}

sub get_version_control
{
    my $self = shift;

    return $self->{'cfg'}->val("quadpres", "version_control");
}

1;


