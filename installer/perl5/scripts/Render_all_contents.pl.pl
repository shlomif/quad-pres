#!/usr/bin/perl -w -I{QP_MODULES_DIR}

use English;

use Shlomif::Quad::Pres::Config;
use Shlomif::Quad::Pres::FS;
use Shlomif::Quad::Pres;
use Shlomif::Quad::Pres::Path;

use Contents;

use strict;

my $cfg = Shlomif::Quad::Pres::Config->new();

my $path_man = Shlomif::Quad::Pres::Path->new();
my $scripts_dir = $path_man->get_scripts_dir();

my $default_dest_dir = $cfg->get_server_dest_dir();
my $render_type = "server";

my $contents = Contents::get_contents();

my $src_dir = "./src/";
my $dest_dir = shift || $default_dest_dir;

if ($src_dir !~ /\/$/)
{
    $src_dir .= "/";
}
if ($dest_dir !~ /\/$/)
{
    $dest_dir .= "/";
}

my $group = $cfg->get_setgid_group();

my $fs_iface = Shlomif::Quad::Pres::FS->new('group' => $group);

# Check if the destination directory exists and if not -
# create it.
$fs_iface->make_dest_dir($dest_dir);

my $render_all = 0;

sub get_file_mtime
{
    my $path = shift;

    return (stat($path))[9];
}



my (@main_files_mtimes) = map { &get_file_mtime($_) } ("Contents.pm", "template.wml");

sub traverse_callback
{
    my (%arguments) = (@_);
    
    my $path_ref = $arguments{'path'};
    my $branch = $arguments{'branch'};

    my (@path);

    @path = @{$path_ref};

    my $p = join("/", @path);

    my ($filename, $src_filename);

    my $is_dir = exists($branch->{'subs'});

    if ($is_dir)
    {
        # It is a directory
        $filename = ($dest_dir . "/" . $p);
        if (! (-d $filename))
        {
            mkdir($filename);
        }
        $filename .= "/index.html";
        $src_filename = $src_dir . "/" . $p . "/index.html";
    }
    else
    {
        $filename = ($dest_dir . "/" . $p);
        $src_filename = $src_dir . "/" . $p;
    }
    $src_filename .= ".wml";
    # Automatically copy the template to the source filename
    if (! -e $src_filename)
    {
        if ($is_dir)
        {
            my $dir_name = $src_filename;
            $dir_name =~ s/\/*index\.html\.wml$//;
            mkdir($dir_name);
        }
        
        open I, "<template.html.wml";
        open O, (">" . $src_filename);
        binmode(I);
        binmode(O);
        print O join("", <I>);
        close(O);
        close(I);
    }
    
    my $src_mtime = get_file_mtime($src_filename);
    my $dest_mtime = get_file_mtime($filename);

    if ((! -e $filename) || 
        (grep 
            { $_ > $dest_mtime } 
            (@main_files_mtimes,$src_mtime)
        ))
    {
        my $src_filename_modified = $src_filename;
        $src_filename_modified =~ s/^(\.\/)?src\/*//;
        my $cmd = "$scripts_dir/render-file.pl \"$src_filename_modified\" > \"$filename\"\n";
            
        print $cmd, "\n";
        (system($cmd) == 0) or die "Aborting.";
    }

    if (exists($branch->{'images'}))
    {
        foreach my $image (@{$branch->{'images'}})
        {
            $filename = $dest_dir . "/" . $p . "/" . $image ;
            $src_filename = $src_dir . "/" . $p . "/" . $image ;

            my $src_mtime = get_file_mtime($src_filename);
            my $dest_mtime = get_file_mtime($filename);
            if ((! -e $filename) ||
                ($src_mtime > $dest_mtime)
                )
            {
                open I, ( "<" . $src_filename);
                open O, ( ">" . $filename);
                binmode(I);
                binmode(O);
                print O join("",<I>);
                close(O);
                close(I);        
            }
        }
    }
}

my $quadpres_obj = 
    Shlomif::Quad::Pres->new(
        $contents, 
        "/",
        "server"
    );

$quadpres_obj->traverse_tree(\&traverse_callback);


