#!/usr/bin/perl -w -I{QP_MODULES_DIR}

use strict;

use Shlomif::Quad::Pres::Config;

use Cwd;

my $cfg = Shlomif::Quad::Pres::Config->new();

my $util = $cfg->get_upload_util();

if (!defined($util))
{
    die "The upload utility was not specified in the quadpres.ini file. Aborting.";
}

my $dest_dir = $cfg->get_server_dest_dir();

my $upload_path = $cfg->get_upload_path();

# Split into the last component of the path and the main
# path up to it.
$dest_dir =~ m{^(.*?)/([^/]*)/*$};
my ($main_path, $last_component) = ($1, $2);

chdir($main_path);
my @command;

if ($util eq "rsync")
{
    @command =
    (
        qw(rsync --progress --verbose --rsh=ssh -r), 
        $last_component . "/",
        $upload_path
    );
}
elsif ($util eq "scp")
{
    @command = 
    (
        qw(scp -r),
        $last_component . "/",
        $upload_path
    )
}
elsif ($util eq "generic")
{
    my $cmd_line = $cfg->get_upload_cmdline();    
    @command = split(/\s+/, $cmd_line);
    foreach (@command)
    {
        s/\${local}/$last_component/g;
        s/\${remote_path}/$upload_path/g;
    }
}
else
{
    die "The upload utility is unrecognized by Quad Pres.";
}

print (join(" ", @command), "\n");
exec(@command);

