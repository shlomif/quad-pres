package Shlomif::Quad::Pres::Path;

use strict;

use Shlomif::Gamla::Object;

use vars qw(@ISA);

@ISA=qw(Shlomif::Gamla::Object);

# This variable will be converted to its right value by the make
# process.
my $pkg_data_dir = "{QP_PKG_DATA_DIR}";

my $modules_dir = "$pkg_data_dir/perl5";

my $scripts_dir = "$pkg_data_dir/scripts";

my $template_dir = "$pkg_data_dir/template";

my $wml_dir = "$pkg_data_dir/wml";

sub get_modules_dir
{
    my $self = shift;

    return $modules_dir;
}

sub get_scripts_dir
{
    my $self = shift;

    return $scripts_dir;
}

sub get_template_dir
{
    my $self = shift;
    return $template_dir;
}

sub get_wml_dir
{
    my $self = shift;

    return $wml_dir;
}

1;

