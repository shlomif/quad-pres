package Shlomif::Quad::Pres::CGI;

use strict;

use Shlomif::Gamla::Object;

use vars qw(@ISA);

@ISA=qw(Shlomif::Gamla::Object);

use CGI;
use Contents;

use MIME::Types;

use POSIX;

use English;

use Shlomif::Quad::Pres::Config;
use Shlomif::Quad::Pres::FS;
use Shlomif::Quad::Pres::Path;

sub is_older
{
    my $file1 = shift;
    my $file2 = shift;
    my @stat1 = stat($file1);
    my @stat2 = stat($file2);
    return ($stat1[9] <= $stat2[9]);
}

sub is_newer
{
    my $file1 = shift;
    my $file2 = shift;
    return (! &is_older($file1, $file2));
}

sub run
{
my $cfg = Shlomif::Quad::Pres::Config->new();

my $group = $cfg->get_setgid_group();

my $fs_iface = Shlomif::Quad::Pres::FS->new('group' => $group);

my $path_man = Shlomif::Quad::Pres::Path->new();
my $scripts_dir = $path_man->get_scripts_dir();

my $q = CGI->new();

#print $q->header();

my $contents = Contents::get_contents();

# Get the path to the file
my ($document_name, $script_name);

if (exists($ENV{'SCRIPT_NAME'}))
{    
    $script_name = $ENV{'SCRIPT_NAME'};
    $document_name = $ENV{'REQUEST_URI'};
    $document_name = substr($document_name, length($script_name));
}
else
{
    $script_name = "";
    $document_name = shift(@ARGV);
}

if ($document_name eq "")
{
    print $q->redirect($script_name . "/");
    exit(0);
}

$document_name =~ s!^\/!!;

my @cgi_path = split(/\//, $document_name);
my @real_path = ();
my $redirect = 0;

while (scalar(@cgi_path))
{
    my $component = shift(@cgi_path);
    if ($component eq "..")
    {
        pop(@real_path);
        $redirect = 1;
    }
    else
    {
        push @real_path, $component;
    }
}

my $error_too_deep = sub {
    print $q->header();
    print "<html><head><title>Too deep a path</title></head><body><p>Too deep a path</p></body></html>";
    exit();    
};

my $type = "branch";
my $branch = $contents;
my @coords = ();
for my $component_idx (0 .. $#real_path)
{
    my $component = $real_path[$component_idx];
    if ((!exists($branch->{'subs'})) && ($component_idx < $#real_path))
    {
        $error_too_deep->();
    }
    my $subs = $branch->{'subs'};
    my $coord = -1;
    for my $i (0 .. $#$subs)
    {
        if ($subs->[$i]->{'url'} eq $component)
        {
            $coord = $i;
            last;
        }
    }
    if ($coord < 0)
    {
        if (($component_idx < $#real_path) || (!exists($branch->{'images'})))
        {
            $error_too_deep->();
        }
        $type = "image";
        my $images = $branch->{'images'};
        for my $i (0 .. $#$images)
        {
            if ($images->[$i] eq $component)
            {
                $coord = $i;
            }
        }
        if ($coord < 0)
        {
            $error_too_deep->();
        }
        push @coords, $coord;
    }
    else
    {
        $branch = $branch->{'subs'}->[$coord];
        push @coords, $coord;
    }
}

my $is_dir = exists($branch->{'subs'});
my $is_not_root_dir = ($is_dir && (scalar(@real_path) > 0));
my $should_end_in_slash = $is_not_root_dir && ($type ne "image");
# If it contains more than one slash
if (($document_name =~ /\/\/$/) || 
    # Or it is a directory and does not contain a slash
    ($should_end_in_slash && ($document_name !~ /\/$/)) ||
    ((!$should_end_in_slash) && ($document_name =~ /\/$/))
   )
{
    $redirect = 1;
}
    

if ($redirect)
{
    print $q->redirect($script_name . "/" . join("/", @real_path) . ($should_end_in_slash ? "/" : ""));
}



my $dest_dir = $cfg->get_server_dest_dir();

# Check if the destination directory exists and if not -
# create it.
$fs_iface->make_dest_dir($dest_dir);

if ($type eq "image")
{
    my $file_path = join("/", @real_path);
    my $mimetypes = MIME::Types->new();
    my MIME::Type $type = $mimetypes->mimeTypeOf($real_path[$#real_path]);
    print $q->header(-type => $type->type());
    
    if ((! -e "$dest_dir/$file_path") || 
        (&is_newer("./src/$file_path", "$dest_dir/$file_path"))
        )
    {
        my $dir_path = "";
        foreach my $component (@real_path[0 .. ($#real_path -1)])
        {
            $dir_path .= "$component/";
            my $dest_dir_path = "$dest_dir/$dir_path";
            if (! -d $dest_dir_path)
            {
                if (!mkdir($dest_dir_path))
                {
                    open I, "./src/$file_path";
                    print join("", <I>);
                    close(I);
                    exit;
                }
            }
        }
        # if (-w "$dest_dir/$file_path")
        {
            open I, "./src/$file_path";
            open O, ">$dest_dir/$file_path";
            print O join("", <I>);
            close(I);
            close(O);
            # my_chown("$dest_dir/$file_path");
        }
    }
    open I, "$dest_dir/$file_path";
    print join("", <I>);
    close(I);
}
else
{
    my $file_path = join("/", @real_path);
    
    print $q->header();
    if ($is_dir)
    {
        $file_path .= "/index.html";
    }
    my $render_file_cmd = "$scripts_dir/render-file.pl \"$file_path\"";
    if ((! -e "$dest_dir/$file_path") || 
        (&is_newer("./src/$file_path.wml", "$dest_dir/$file_path")) ||
        (&is_newer("template.wml", "$dest_dir/$file_path")) ||
        (&is_newer("Contents.pm", "$dest_dir/$file_path"))
        )
    {
        my $dir_path = "";
        #foreach my $component (@real_path[0 .. ($#real_path -1)])
        for my $num_components (1 .. @real_path-($is_dir ? 0 : 1))
        {
            #$dir_path .= "$component/";
            $dir_path = join("/", @real_path[0 .. ($num_components-1)]);
            my $dest_dir_path = "$dest_dir/$dir_path";
            $dest_dir_path =~ s{/+$}{};
            if (! -e $dest_dir_path)
            {
                if (!mkdir($dest_dir_path))
                {
                    system($render_file_cmd);
                    exit();
                }
            }
        }
        {
            system("$render_file_cmd > \"$dest_dir/$file_path\"");
            # my_chown("$dest_dir/$file_path");
        };
    }
    open I, "$dest_dir/$file_path";
    print join("", <I>);
    close(I);
}
}

