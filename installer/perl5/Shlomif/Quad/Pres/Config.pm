package Shlomif::Quad::Pres::Config;

use strict;
use warnings;

use parent 'Games::Solitaire::Verify::Base';

use Cwd;

use Config::IniFiles;
use Template;

__PACKAGE__->mk_acc_ref([qw( base_path cfg )]);

sub _init
{
    my $self = shift;

    my %args = @_;

    my $base_path = $args{path} || ".";

    $self->base_path( $base_path );

    my $cfg =
        Config::IniFiles->new(
            -file => "$base_path/quadpres.ini"
        );

    if (!defined($cfg))
    {
        die "Could not open the configuration file!";
    }

    $self->cfg($cfg);

    return 0;
}

sub _get_raw_val
{
    my $self = shift;
    return $self->cfg->val(@_);
}

sub _get_tt_driver
{
    return Template->new({});
}

sub _get_tt_vars
{
    my $vars =
    {
        'ENV' => \%ENV,
    };

    return $vars;
}

sub _get_tt_val
{
    my ($self, $section, $key, $value) = @_;

    my $template = $self->_get_raw_val($section, "tt_$key", $value);

    if (!defined($template))
    {
        return;
    }

    my $output = "";
    $self->_get_tt_driver()->process(
        \$template,
        $self->_get_tt_vars(),
        \$output,
    );

    return $output;
}

sub get_val
{
    my $self = shift;

    # TODO : I'm assuming it's always scalar context here.
    my $tt_value = $self->_get_tt_val(@_);

    if (defined($tt_value))
    {
        return $tt_value;
    }
    else
    {
        return $self->_get_raw_val(@_);
    }
}

sub get_server_dest_dir
{
    my $self = shift;

    return $self->get_val("quadpres", "server_dest_dir");
}

sub get_setgid_group
{
    my $self = shift;

    return $self->get_val("quadpres", "setgid_group");
}

sub get_upload_path
{
    my $self = shift;

    return $self->get_val("upload", "upload_path");
}

sub get_upload_util
{
    my $self = shift;

    return $self->get_val("upload", "util");
}

sub get_upload_cmdline
{
    my $self = shift;

    return $self->get_val("upload", "cmdline");
}

sub get_version_control
{
    my $self = shift;

    return $self->get_val("quadpres", "version_control");
}

sub get_hard_disk_dest_dir
{
    my $self = shift;

    return $self->get_val("hard-disk", "dest_dir");
}

sub get_src_archive_path
{
    my $self = shift;

    return $self->get_val("quadpres", "src_archive");
}

1;


