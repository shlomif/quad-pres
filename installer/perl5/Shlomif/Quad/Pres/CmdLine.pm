package Shlomif::Quad::Pres::CmdLine;

use strict;
use warnings;

# use autodie;

use Scalar::Util qw(blessed);

use English qw( -no_match_vars );
use Pod::Usage (qw( pod2usage ));
use Cwd        (qw( getcwd ));
use Data::Dumper;
use File::Copy     (qw( copy ));
use File::Path     ();
use File::Basename (qw( dirname));
use Carp           ();
use File::Spec;
use HTML::Links::Localize;
use File::Glob ':glob';

use IO::All qw/ io /;

use Shlomif::Quad::Pres::Path;
use Shlomif::Quad::Pres::Exception;
use Shlomif::Quad::Pres::Getopt;
use Shlomif::Quad::Pres::Config;
use Shlomif::Quad::Pres;
use Shlomif::Quad::Pres::FS;
use Shlomif::Quad::Pres::WriteContents;

use lib getcwd();

use MooX qw/ late /;

use lib do { `wml-params-conf --show-privlib` =~ s#[\r\n]+\z##r };
use TheWML::Frontends::Wml::Runner ();

has 'dest_dir'          => ( isa => 'Str',      'is' => 'rw' );
has 'src_dir'           => ( isa => 'Str',      'is' => 'rw' );
has 'main_files_mtimes' => ( isa => 'ArrayRef', 'is' => 'rw' );
has 'getopt'            => (
    isa     => "Shlomif::Quad::Pres::Getopt",
    'is'    => "ro",
    lazy    => 1,
    default => sub {
        return Shlomif::Quad::Pres::Getopt->new( shift->cmd_line );
    },
);
has 'invocation_path' => ( isa => "ArrayRef", is => "rw" );
has 'path_man' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return Shlomif::Quad::Pres::Path->new;
    },
);
has 'cmd_line' => ( isa => 'ArrayRef', is => 'ro', required => 1 );
has '_wml_obj' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return TheWML::Frontends::Wml::Runner->new;
    },
);

my $error_class = "Shlomif::Quad::Pres::Exception";

sub _init_cmd_line
{
    my ( $self, $cmd_line ) = @_;

    if ( !defined($cmd_line) )
    {
        $error_class->throw( { text => 'cmd_line not specified' } );
    }

    $self->cmd_line($cmd_line);

    $self->getopt( Shlomif::Quad::Pres::Getopt->new($cmd_line) );

    return;
}

sub gen_aliases
{
    my $command = shift;
    my $aliases = shift;

    return ( map { $_ => $command } ( $command, @$aliases ) );
}

my %cmd_aliases;

my %registered_commands;

sub _register_cmd
{
    my $command  = shift;
    my $callback = shift || "perform_${command}_command";
    my $aliases  = shift || [];

    %cmd_aliases = ( %cmd_aliases, gen_aliases( $command, $aliases ) );
    $registered_commands{$command} = $callback;

    return;
}

_register_cmd('clear');
_register_cmd( 'render',                 0, [qw(rend)] );
_register_cmd( 'render_all_in_one_page', 0, [qw(all_in_one)] );
_register_cmd('setup');
_register_cmd('upload');
_register_cmd('add');
_register_cmd('pack');

sub run_command
{
    my $self = shift;

    my %args = (@_);

    my $command    = $args{command};
    my $error_text = $args{error_text};

    my $cmd_ret;

    if ( ref($command) eq "ARRAY" )
    {
        $cmd_ret = system(@$command);
    }
    else
    {
        $cmd_ret = system($command);
    }

    if ( $cmd_ret != 0 )
    {
        $error_class->throw( { text => $error_text } );
    }

    return 0;
}

sub run
{
    my $self = shift;

    my $ret;
    eval { $ret = $self->real_run(); };

    if ( my $E = $@ )
    {
        if ( blessed($E) && $E->isa($error_class) )
        {
            print STDERR "Quad-Pres Error: ", $E->text(), "\n";
        }
        else
        {
            print STDERR "$E\n";
        }
        $ret = -1;
    }

    return $ret;
}

sub real_run
{
    my $self = shift;

    my ( $help, $man );

    my $getopt = $self->getopt();

    $getopt->configure('require_order');
    $getopt->getoptions(
        'help|h|?' => \$help,
        'man'      => \$man,
    ) or pod2usage(2);

    pod2usage(1) if $help;
    pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

    my $command =
        $self->_get_cl_param( { 'empty_cb' => sub { pod2usage(1) }, }, );

    if ( !exists( $cmd_aliases{$command} ) )
    {
        $error_class->throw( { text => "Unknown Command \"$command\"!" } );
    }

    my $callback = $registered_commands{ $cmd_aliases{$command} };

    return $self->$callback();
}

sub get_dir_path
{
    my $dir = shift;
    my $pwd = getcwd();

    chdir($dir);
    my $ret = getcwd();
    chdir($pwd);
    return $ret;
}

sub _get_cl_param
{
    my ( $self, $args ) = @_;

    if ( !@{ $self->cmd_line() } )
    {
        if ( exists( $args->{empty_cb} ) )
        {
            return $args->{empty_cb}->();
        }
        $error_class->throw( { text => $args->{error_text} } );
    }

    return shift( @{ $self->cmd_line() } );
}

sub perform_setup_command
{
    my $self = shift;

    my $getopt = $self->getopt();

    my $src_dir_name = $self->_get_cl_param(
        { 'error_text' => "setup must be followed by a directory name" } );

    my %args = (
        "server_dest_dir" => undef,
        "setgid_group"    => "",
        "upload_path"     => "",
    );

    $getopt->getoptions(
        'dest-dir=s'     => \$args{"server_dest_dir"},
        'setgid-group=s' => \$args{"setgid_group"},
        'upload-path=s'  => \$args{"upload_path"},
    );

    if ( !defined( $args{"server_dest_dir"} ) )
    {
        $error_class->throw(
            {
                text => 'You must specify --dest-dir with something meaningful!'
            }
        );
    }

    if ( !mkdir($src_dir_name) )
    {
        $error_class->throw(
            {
                text => "Could not create the source directory.\nErrno=$!"
            }
        );
    }

    io->file("$src_dir_name/quadpres.ini")->print( <<"EOF" );
[quadpres]

; The destination direcory in which to place the rendered files.
server_dest_dir=$args{server_dest_dir}

; The group to which the files should be associated with (defaults
; to the user's default group)
setgid_group=$args{setgid_group}

[upload]

; Can be either one of:
; 1. rsync
; 2. scp
; 3. generic - in which case a generic command line is spcified.
util=rsync

; The remote path that should be used to upload the files to
upload_path=$args{upload_path}

; Specify a generic command line here
; You can use:
; \${local} - the location of the local path.
; \${remote_path} - the upload path configuration from this file.
;cmdline=

[hard-disk]

; The destination directory for the files that are viewable on the
; the hard disk without a web-server.
dest_dir=./hard-disk-html/
EOF

    io->file("$src_dir_name/.wmlrc")
        ->print("-DROOT~src --passoption=2,-X3074 -DTHEME=shlomif-text\n");

    io->file("$src_dir_name/Contents.pm")->print(
        (
            "package Contents;\n\n",
            "use strict;\n\n",
            "my \$contents =\n",
            "{\n",
            "    'title' => \"My Lecture Title\",\n",
            "    'subs' =>\n",
            "    [\n",
            "    ],\n",
            "    'images' =>\n",
            "    [\n",
            "        'style.css',\n",
            "    ],\n",
            "};\n\n",
            "sub get_contents\n",
            "{\n",
            "    return \$contents;\n",
            "}\n",
            "\n",
            "1;\n"
        )
    );

    "\n\n#include \"quadpres_main.wml\"\n\n" >
        io->file("$src_dir_name/template.wml");

    my $modules_dir = $self->path_man()->get_modules_dir();

    # Prepare the serve.pl file that can be used to serve it using a CGI;
    my $serve_filename = "$src_dir_name/serve.pl";
    io->file($serve_filename)->print( <<"EOF" );
#!/usr/bin/perl -w -I$modules_dir

use strict;
use Shlomif::Quad::Pres::CGI;

my \$cgi = Shlomif::Quad::Pres::CGI->new();

\$cgi->run();

EOF
    chmod 0755, $serve_filename;

    mkdir("$src_dir_name/src");

    my $template_dir = $self->path_man()->get_template_dir();

    copy( "$template_dir/style.css", "$src_dir_name/src/style.css" );
    copy( "$template_dir/template.html.wml",
        "$src_dir_name/template.html.wml" );

    # Create a file indicating that this is the root directory.
    # Regular named files may be present somewhere inside the ./src
    # directory for all we know.
    mkdir("$src_dir_name/.quadpres");
    io->file("$src_dir_name/.quadpres/is_root")->print('');

    print "Successfully Created $src_dir_name\n";

    return 0;
}

sub chdir_to_base
{
    my $self = shift;

    my $current_path = getcwd();
    my @path = split( /\//, $current_path );

    my $levels_num = 0;

    # Go to the base dir.
    while ( !-e ".quadpres/is_root" )
    {
        chdir("..");
        $levels_num++;
        if ( getcwd() eq "/" )
        {
            $error_class->throw(
                {
                    text => 'Could not find the Quad-Pres root anywhere',
                }
            );
        }
    }

    # Assign invocation_path the components from the quad-pres base
    # directory to the place where the script was invoked.
    $self->invocation_path(
        [ @path[ ( scalar(@path) - $levels_num ) .. $#path ] ] );

    return 0;
}

sub perform_render_command
{
    my $self = shift;

    my $cmd_line = $self->cmd_line();
    my $getopt   = $self->getopt();

    if ( !@$cmd_line )
    {
        $error_class->throw(
            { text => 'render must be followed by filenames or flags' } );
    }

    my $render_all            = 0;
    my $render_hard_disk_html = 0;

    $getopt->getoptions(
        'a|all!'        => \$render_all,
        'hd|hard-disk!' => \$render_hard_disk_html,
    );

    if ( !$render_all )
    {
        $error_class->throw(
            { text => "Don't know how to render anything but all yet.", } );
    }

    $self->chdir_to_base();

    eval { $self->_render_all_contents(); };
    my $error = $@;
    if (   $error
        && blessed($error)
        && $error->isa('Shlomif::Quad::Pres::Exception::RenderFile') )
    {
        $error_class->throw( { text => "Rendering Failed!" } );
    }

    # $self->run_command(
    #     'command' => "$scripts_dir/Render_all_contents.pl",
    #     'error_text' => "Rendering Failed!",
    # );

    if ($render_hard_disk_html)
    {
        $self->_convert_to_hardisk();
    }

    return 0;
}

sub _convert_to_hardisk
{
    my $self = shift;

    my $cfg = Shlomif::Quad::Pres::Config->new();

    my $default_dest_dir = $cfg->get_server_dest_dir();

    my $hard_disk_dest_dir = $cfg->get_hard_disk_dest_dir();

    my $converter = HTML::Links::Localize->new(
        'base_dir' => $default_dest_dir,
        'dest_dir' => $hard_disk_dest_dir,
    );

    $converter->process_dir_tree( 'only-newer' => 1 );

    return;
}

sub _get_file_mtime
{
    my ( $self, $path ) = @_;

    return ( stat($path) )[9];
}

sub _render_all_contents_traverse_callback
{
    my $self = shift;
    my (%arguments) = (@_);

    my $path_ref = $arguments{'path'};
    my $branch   = $arguments{'branch'};

    my (@path);

    @path = @{$path_ref};

    my $p = join( "/", @path );

    {
        my ( $filename, $src_filename );

        my $is_dir = exists( $branch->{'subs'} );

        my $src_dir = $self->src_dir();

        if ($is_dir)
        {
            # It is a directory
            $filename = ( $self->dest_dir() . "/" . $p );
            if ( !( -d $filename ) )
            {
                mkdir($filename);
            }
            $filename .= "/index.html";
            $src_filename = $src_dir . "/" . $p . "/index.html";
        }
        else
        {
            $filename     = ( $self->dest_dir() . "/" . $p );
            $src_filename = $src_dir . "/" . $p;
        }
        $src_filename .= ".wml";

        # Automatically copy the template to the source filename
        if ( !-e $src_filename )
        {
            if ($is_dir)
            {
                my $dir_name = $src_filename;
                $dir_name =~ s/\/*index\.html\.wml$//;
                mkdir($dir_name);
            }

            io->file("template.html.wml") > io->file($src_filename);
        }

        {
            my $src_mtime  = $self->_get_file_mtime($src_filename);
            my $dest_mtime = $self->_get_file_mtime($filename);

            if (
                ( !-e $filename )
                || ( grep { $_ > $dest_mtime }
                    ( @{ $self->main_files_mtimes() }, $src_mtime ) )
                )
            {
                my $src_filename_modified = $src_filename;
                $src_filename_modified =~ s/^(\.\/)?src\/*//;
                $self->_render_file(
                    {
                        input_fn  => $src_filename_modified,
                        output_fn => $filename,
                    },
                );
            }
        }
    }

    if ( exists( $branch->{'images'} ) )
    {
        foreach my $image ( @{ $branch->{'images'} } )
        {
            my $filename     = $self->dest_dir() . "/" . $p . "/" . $image;
            my $src_filename = $self->src_dir() . "/" . $p . "/" . $image;

            my $src_mtime  = $self->_get_file_mtime($src_filename);
            my $dest_mtime = $self->_get_file_mtime($filename);

            if (   ( !-e $filename )
                || ( $src_mtime > $dest_mtime ) )
            {
                copy_with_creating_dir( $src_filename, $filename );
            }
        }
    }

    return;
}

sub _render_file
{
    my ( $self, $args ) = @_;

    my $filename        = $args->{input_fn};
    my $output_filename = $args->{output_fn};

    $filename =~ s{\.wml$}{};
    $filename =~ s{/$}{/index.html};

    my $path_man = Shlomif::Quad::Pres::Path->new();

    my $wml_dir     = $path_man->get_wml_dir();
    my $modules_dir = $path_man->get_modules_dir();

    my $local_wml_dir = $ENV{"HOME"} . "/.Quad-Pres/lib/";

    my @local_wml =
        $ENV{"QUAD_PRES_NO_HOME_LIB"}
        ? ()
        : ( "-I", $local_wml_dir );

    my @command = (
        "-I", $wml_dir, @local_wml, "-DFILENAME=$filename",
        "--passoption=3,-I$modules_dir",
        "-o", $output_filename, "src/$filename.wml"
    );

    if ( !$ENV{"QUAD_PRES_QUIET"} )
    {
        print join( " ", 'wml', @command ), "\n";
    }

    my $ret = -1;

    eval { $ret = $self->_wml_obj->run_with_ARGV( { ARGV => [@command], } ); };

    # If it failed.
    if ( $@ or $ret != 0 )
    {
        # Clean-up the file so it will have to be regenerated
        my $error = Shlomif::Quad::Pres::Exception::RenderFile->new();
        $error->{'src_filename'} = $filename;
        die $error;
    }

    return;
}

=begin Removed

        my $cmd = "$scripts_dir/render-file.pl \"$src_filename_modified\" > \"$filename\"\n";

        print $cmd, "\n";
        if (system($cmd) != 0)
        {
            # Clean-up the file so it will have to be regenerated
            unlink($filename);
            my $error = Shlomif::Quad::Pres::Exception::RenderFile->new();
            $error->{'src_filename'} = $src_filename;
            die $error;
        }

=end

=cut

sub _assign_src_dir
{
    my $self = shift;

    my $src_dir = "./src/";

    if ( $src_dir !~ /\/$/ )
    {
        $src_dir .= "/";
    }

    $self->src_dir($src_dir);

    return;
}

sub _render_all_contents
{
    my $self = shift;

    my $cfg = Shlomif::Quad::Pres::Config->new();

    my $default_dest_dir = $cfg->get_server_dest_dir();
    my $render_type      = "server";

    require Contents;
    my $contents = Contents::get_contents();

    $self->_assign_src_dir();

    my $dest_dir = shift || $default_dest_dir;

    if ( $dest_dir !~ /\/$/ )
    {
        $dest_dir .= "/";
    }

    $self->dest_dir($dest_dir);

    my $group = $cfg->get_setgid_group();

    my $fs_iface = Shlomif::Quad::Pres::FS->new( 'group' => $group );

    # Check if the destination directory exists and if not -
    # create it.
    $fs_iface->make_dest_dir($dest_dir);

    my $render_all = 0;

    $self->main_files_mtimes(
        [
            map { $self->_get_file_mtime($_) } ( "Contents.pm", "template.wml" )
        ]
    );

    my $quadpres_obj = Shlomif::Quad::Pres->new(
        $contents,
        'doc_id' => "/",
        'mode'   => "server",
    );

    $quadpres_obj->traverse_tree(
        sub { $self->_render_all_contents_traverse_callback(@_) } );

    return;
}

sub perform_clear_command
{
    my $self = shift;

    my $cmd_line = $self->cmd_line();
    my $getopt   = $self->getopt();

    if ( !@$cmd_line )
    {
        $error_class->throw(
            { text => 'clear must be followed by filenames or flags', } );
    }

    my $clear_all = 0;

    $getopt->getoptions( 'a|all!' => \$clear_all );

    if ( !$clear_all )
    {
        $error_class->throw(
            { text => q{Don't know how to clear anything but all yet.}, } );
    }

    # Go to the base dir.
    $self->chdir_to_base();

    my $cfg = Shlomif::Quad::Pres::Config->new();

    my $dest_dir = $cfg->get_server_dest_dir();

    File::Path::rmtree( [$dest_dir], 0, 0 );

    return 0;
}

sub perform_upload_command
{
    my $self = shift;

    $self->chdir_to_base();

    my $cfg = Shlomif::Quad::Pres::Config->new();

    my $util = $cfg->get_upload_util();

    if ( !defined($util) )
    {
        Carp::confess(
"The upload utility was not specified in the quadpres.ini file. Aborting."
        );
    }

    my $dest_dir = $cfg->get_server_dest_dir();

    my $upload_path = $cfg->get_upload_path();

    # Split into the last component of the path and the main
    # path up to it.
    $dest_dir =~ m{^(.*?)/([^/]*)/*$};
    my ( $main_path, $last_component ) = ( $1, $2 );

    chdir($main_path);
    my @command;

    if ( $util eq "rsync" )
    {
        @command = (
            qw(rsync --progress --verbose --rsh=ssh -a),
            $last_component . "/", $upload_path
        );
    }
    elsif ( $util eq "scp" )
    {
        @command = ( qw(scp -r), $last_component . "/", $upload_path );
    }
    elsif ( $util eq "generic" )
    {
        my $cmd_line = $cfg->get_upload_cmdline();
        @command = split( /\s+/, $cmd_line );
        foreach (@command)
        {
            s/\$\{local\}/$last_component/g;
            s/\$\{remote_path\}/$upload_path/g;
        }
    }
    else
    {
        Carp::confess("The upload utility is unrecognized by Quad Pres.");
    }

    print( join( " ", @command ), "\n" );
    return system(@command);
}

sub add_filename_to_path
{
    my $self = shift;

    my $orig_path = shift;
    my @path      = @$orig_path;

    my $filename = shift;

    my @fn_path = split( /\//, $filename );

COMPS:
    foreach my $component (@fn_path)
    {
        if ( $component eq "." )
        {
            next COMPS;
        }
        if ( $component eq ".." )
        {
            if ( !@path )
            {
                $error_class->throw(
                    {
                        text => (
                                  'Path given exits from the lecture source'
                                . ' code base directory'
                        ),
                    }
                );
            }
            else
            {
                pop(@path);
            }
            next COMPS;
        }
        push( @path, $component );
    }

    return \@path;
}

sub perform_add_command
{
    my $self = shift;

    my $cmd_line = $self->cmd_line();

    $self->chdir_to_base();

    my $filename =
        $self->_get_cl_param( { 'error_text' => "add needs a filename" } );

    my @path = @{ $self->invocation_path() };

    my $file_path = $self->add_filename_to_path( \@path, $filename );

    if ( $file_path->[0] ne "src" )
    {
        $error_class->throw(
            { text => "Cannot add files outside the src directory", },
        );
    }

    # Remove "src" from the file path
    shift(@$file_path);

    $filename = join( "/", "src", @$file_path );

    if ( !-e $filename )
    {
        $error_class->throw(
            {
                text => "File \"$filename\" does not exist"
            }
        );
    }

    require Contents;

    my $contents = Contents::get_contents();

    my $current_section = $contents;

    foreach my $component ( @$file_path[ 0 .. ( $#$file_path - 1 ) ] )
    {
        my $next_section;
    SUB_SECT_SEARCH: foreach my $sub_sect ( @{ $current_section->{subs} } )
        {
            if ( $sub_sect->{url} eq $component )
            {
                $next_section = $sub_sect;
                last SUB_SECT_SEARCH;
            }
        }
        if ( !defined($next_section) )
        {
            $error_class->throw(
                {
                    text => (
                              "Could not find the relevant section in "
                            . "the lecture's table of contents"
                    )
                }
            );
        }
        $current_section = $next_section;
    }
    my $last_component = $file_path->[$#$file_path];
    if ( $last_component !~ /\.wml$/ )
    {
        $error_class->throw(
            {
                text => "The Filename \"$last_component\" is not a slide."
            }
        );
    }
    $last_component =~ s/\.wml$//;
    if ( ( grep { $_->{url} eq $last_component } @{ $current_section->{subs} } )
        || ( grep { $_ eq $last_component } @{ $current_section->{images} } ) )
    {
        $error_class->throw(
            {
                text => "The File already exists in the lecture.",
            }
        );
    }
    my $is_dir = ( -d $filename );
    my $title  = "My Title";
    push @{ $current_section->{subs} },
        {
        url   => $last_component,
        title => $title,
        ( $is_dir ? ( subs => [] ) : () )
        };

    my $writer =
        Shlomif::Quad::Pres::WriteContents->new( contents => $contents );
    $writer->update_contents();

    return 0;
}

sub copy_with_creating_dir
{
    my ( $src_fn, $dest_fn ) = @_;
    File::Path::mkpath( [ dirname($dest_fn) ] );
    return copy( $src_fn, $dest_fn );
}

sub _traverse_pack_callback
{
    my $self = shift;

    my (%arguments) = (@_);

    my $path_ref = $arguments{'path'};
    my $branch   = $arguments{'branch'};

    my (@path);

    @path = @{$path_ref};

    my $p = join( "/", @path );

    {
        my ( $filename, $src_filename );

        my $is_dir = exists( $branch->{'subs'} );

        my $src_dir = $self->src_dir();

        if ($is_dir)
        {
            # It is a directory
            $filename = ( $self->src_archive_src_dir() . "/" . $p );
            if ( !( -d $filename ) )
            {
                mkdir($filename);
            }
            copy( $src_dir . "/" . $p . "/index.html.wml",
                "$filename/index.html.wml" );
        }
        else
        {
            $filename     = ( $self->src_archive_src_dir() . "/" . $p );
            $src_filename = $src_dir . "/" . $p;
            copy( $src_filename . ".wml", $filename . ".wml" );
        }
    }

    if ( exists( $branch->{'images'} ) )
    {
        foreach my $image ( @{ $branch->{'images'} } )
        {
            my $filename =
                $self->src_archive_src_dir() . "/" . $p . "/" . $image;
            my $src_filename = $self->src_dir() . "/" . $p . "/" . $image;

            File::Path::mkpath( [ dirname($filename) ] );
            copy_with_creating_dir( $src_filename, $filename );
        }
    }

    return;
}

sub src_archive_dir
{
    my $self = shift;

    return "./SOURCE";
}

sub src_archive_src_dir
{
    my $self = shift;

    return $self->src_archive_dir() . "/src";
}

sub perform_pack_command
{
    my $self = shift;

    my $cfg = Shlomif::Quad::Pres::Config->new();

    $self->_assign_src_dir();

    my $src_archive_name = $cfg->get_src_archive_path()
        || ( $cfg->get_server_dest_dir() . "/" . "src.tar.gz" );

    File::Path::rmtree( [ $self->src_archive_dir() ], 0, 0 );

    mkdir( $self->src_archive_dir() );
    mkdir( $self->src_archive_dir() . "/.quadpres" );

    # Copy the files from the root directory.
    foreach my $file (
        sort { $a cmp $b }
        grep { -f $_ }
        map  { bsd_glob($_) }
        qw(*.pm *.wml *.html quadpres.ini *.pl *.sh .quadpres/* .wmlrc)
        )
    {
        copy( $file, $self->src_archive_dir() . "/$file" );
    }

    mkdir( $self->src_archive_src_dir() );

    require Contents;
    my $contents = Contents::get_contents();

    my $quadpres_obj = Shlomif::Quad::Pres->new(
        $contents,
        'doc_id' => "/",
        'mode'   => "server",
    );

    $quadpres_obj->traverse_tree(
        sub {
            return $self->_traverse_pack_callback(@_);
        }
    );

    system( "tar", "-czf", $src_archive_name, $self->src_archive_dir() );

    return 0;
}

sub _calc_page_id
{
    my $link_path_ref = shift;

    my @link_path = @$link_path_ref;

    if ( @link_path && $link_path[-1] =~ s{\.html\z}{} )
    {
        push @link_path, "PAGE";
    }
    else
    {
        push @link_path, "DIR";
    }

    return join( "--", "page", @link_path );
}

sub perform_render_all_in_one_page_command
{
    use autodie;
    my $self = shift;

    my $cmd_line = $self->cmd_line();
    my $getopt   = $self->getopt();

    if ( !@$cmd_line )
    {
        $error_class->throw(
            { text => 'render must be followed by filenames or flags' } );
    }

    my $all_in_one_dir;
    $getopt->getoptions( 'output-dir=s' => \$all_in_one_dir, );
    if ( !defined $all_in_one_dir )
    {
        $error_class->throw( { text => 'please specify an --output-dir.', } );
    }

    require Contents;

    my $contents = Contents::get_contents();

    my $cfg = Shlomif::Quad::Pres::Config->new();

    my $dest_dir = $cfg->get_server_dest_dir();

    if ( $dest_dir !~ m{/\z} )
    {
        $dest_dir .= "/";
    }

    my $group = $cfg->get_setgid_group();

    my $quadpres_obj = Shlomif::Quad::Pres->new(
        $contents,
        'doc_id' => "/",
        'mode'   => "server",
    );

    mkdir($all_in_one_dir);
    my $all_fn = "$all_in_one_dir/index.html";
    open my $all_in_one_out_fh, ">", $all_fn;

    my $is_first              = 1;
    my $_render_to_all_in_one = sub {
        my (%arguments) = (@_);

        my $path_ref = $arguments{'path'};
        my $branch   = $arguments{'branch'};

        my (@path);

        @path = @{$path_ref};

        my $p = join( "/", @path );

        {
            my $filename;

            my $is_dir = exists( $branch->{'subs'} );

            if ($is_dir)
            {
                # It is a directory
                $filename = ( $dest_dir . "/" . $p );
                $filename .= "/index.html";
            }
            else
            {
                $filename = ( $dest_dir . "/" . $p );
            }

            open my $in, "<", $filename;
            local $/;
            my $text = <$in>;

            if ( !$is_first )
            {
                $text =~
                    s{.*?(<nav>[\s\n\r]*<table class="page-nav-bar top")}{$1}ms;
            }
            else
            {
                $text =~ s{<link rel="(?:top|next|first|last)".*?/>}{}gms;
                $text =~
s{\Q<!-- Beginning of Project Wonderful ad code: -->\E.*\Q<!-- End of Project Wonderful ad code. -->\E}{}ms;
            }
            $is_first = 0;

            # Remove the trailing stuff.
            $text =~ s{<nav>[\s\n\r]*<table class="page-nav-bar bottom".*}{}ms;

            my $fix_internal_link = sub {
                my $link_text = shift;

                my $is_current_dir = $is_dir;

                # Preserve absolute links to the outside world.
                if ( $link_text =~ m{\A[\w\-\+]+:} )
                {
                    return $link_text;
                }

                my @link_path = @path;

                foreach my $component ( split( m{/}, $link_text ) )
                {
                    if ( $component eq "." )
                    {
                        if ( !$is_current_dir )
                        {
                            pop(@link_path);
                            $is_current_dir = 1;
                        }
                    }
                    elsif ( $component eq ".." )
                    {
                        pop(@link_path);
                    }
                    else
                    {
                        if ( !$is_current_dir )
                        {
                            pop(@link_path);
                            $is_current_dir = 1;
                        }

                        push @link_path, $component;
                    }
                }

                return "#" . _calc_page_id( \@link_path );
            };

            # Fix the internal links
            $text =~ s{(<a href=")([^"]+)(")}
             {$1 . $fix_internal_link->($2) . $3}egms
                ;

            my $div_tag = qq{<section class="page">\n};

            my $id_attr = qq{ id="} . _calc_page_id( \@path ) . qq{"};

            if ( $text !~ s{(<body[^>]*>)}{$1$div_tag}ms )
            {
                $text = $div_tag . $text;
            }

            $text =~ s{<h1>}{<h1$id_attr>};
            $text =~ s%</?main>%%g;

            print {$all_in_one_out_fh} $text, qq{\n</section>\n};
            close($in);
        }
        if ( exists( $branch->{'images'} ) )
        {
            foreach my $image ( @{ $branch->{'images'} } )
            {
                my $src_filename  = $dest_dir . "/" . $p . "/" . $image;
                my $dest_filename = $all_in_one_dir . "/" . $p . "/" . $image;

                my $src_mtime  = _get_file_mtime( undef, $src_filename );
                my $dest_mtime = _get_file_mtime( undef, $dest_filename );

                if (   ( !-e $dest_filename )
                    || ( $src_mtime > $dest_mtime ) )
                {
                    copy_with_creating_dir( $src_filename, $dest_filename );
                }
            }
        }

    };

    $quadpres_obj->traverse_tree($_render_to_all_in_one);

    print {$all_in_one_out_fh} "\n</body></html>\n";
    close($all_in_one_out_fh);

    return 0;
}

1;
