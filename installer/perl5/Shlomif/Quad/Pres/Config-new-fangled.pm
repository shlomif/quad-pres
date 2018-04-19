package Shlomif::Quad::Pres::Config;

use strict;
use warnings;

use parent 'Shlomif::Quad::Pres::Base';

__PACKAGE__->mk_acc_ref([qw( base_path cfg )]);

use Config::IniFiles;

sub initialize
{
    my $self = shift;
    my %args = @_;

    my $base_path = $args{path} || ".";

    $self->base_path($base_path);

    my $cfg =
        Config::IniFiles->new(
            -file => "$base_path/quadpres.ini"
        );

    if (!defined($cfg))
    {
        die "Could not open the configuration file!";
    }

    $self->cfg( $cfg );

    return 0;
}

sub get_server_dest_dir
{
    my $self = shift;

    return $self->cfg->val("quadpres", "server_dest_dir");
}

sub get_setgid_group
{
    my $self = shift;

    return $self->cfg->val("quadpres", "setgid_group");
}

sub get_rsync_upload_path
{
    my $self = shift;

    return $self->cfg->val("rsync", "upload_path");
}

sub get_version_control
{
    my $self = shift;

    return $self->cfg->val("quadpres", "version_control");
}

1;


