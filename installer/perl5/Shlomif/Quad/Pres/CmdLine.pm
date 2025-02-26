package Shlomif::Quad::Pres::CmdLine;

use 5.014;
use strict;
use warnings;
use autodie;

use Scalar::Util qw( blessed );

use Pod::Usage (qw( pod2usage ));
use File::ShouldUpdate    qw( should_update );
use Carp                  ();
use HTML::Links::Localize ();
use File::Glob            qw( bsd_glob );

use Path::Tiny qw/ cwd path /;

use Shlomif::Quad::Pres::Path ();
use QuadPres::Exception       ();
use QuadPres::Config          ();
use QuadPres 0.30.0           ();
use QuadPres::FS              ();
use QuadPres::WriteContents   ();

use lib cwd()->stringify();

use MooX qw/ late /;

use lib do { `wml-params-conf --show-privlib` =~ s#[\r\n]+\z##r };
use TheWML::Frontends::Wml::Runner ();

has '_cache_dir'            => ( 'is' => 'rw' );
has '_all_in_one_cache_dir' => ( 'is' => 'rw' );
has 'dest_dir'              => ( isa  => 'Str',      'is' => 'rw' );
has 'src_dir'               => ( isa  => 'Str',      'is' => 'rw' );
has 'main_files_mtimes'     => ( isa  => 'ArrayRef', 'is' => 'rw' );
has 'getopt' => (
    isa     => "Getopt::Long::Parser",
    'is'    => "ro",
    lazy    => 1,
    default => sub {
        use Getopt::Long ();
        return Getopt::Long::Parser->new;
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

my $error_class = "QuadPres::Exception";

my $TIMESTAMP = $ENV{QUAD_PRES_SRC_TS} // 0;

sub _set_time
{
    my ( $self, @paths ) = @_;

    foreach my $p (@paths)
    {
        path($p)->touchpath()->touch($TIMESTAMP);
    }
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
    my $command = shift;
    my $aliases = shift || [];

    %cmd_aliases = ( %cmd_aliases, gen_aliases( $command, $aliases ) );
    my $callback = "perform_${command}_command";
    $registered_commands{$command} = $callback;

    return;
}

_register_cmd( 'render',                 [qw(rend)] );
_register_cmd( 'render_all_in_one_page', [qw(all_in_one)] );

_register_cmd('add');
_register_cmd('clear');
_register_cmd('pack');
_register_cmd('setup');
_register_cmd('upload');

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
    $getopt->getoptionsfromarray(
        $self->cmd_line,
        'help|h|?' => \$help,
        'man'      => \$man,
    ) or pod2usage(2);

    pod2usage(1)                                 if $help;
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

    $getopt->getoptionsfromarray(
        $self->cmd_line,
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

    if ( !path($src_dir_name)->mkpath() )
    {
        $error_class->throw(
            {
                text => "Could not create the source directory.\nErrno=$!"
            }
        );
    }

    path("$src_dir_name/quadpres.ini")->spew_raw(<<"EOF");
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

    path("$src_dir_name/.wmlrc")
        ->spew_raw("-DROOT~src --passoption=2,-X3074 -DTHEME=shlomif-text\n");

    path("$src_dir_name/Contents.pm")->spew_raw(
        <<"EOF"
package Contents;

use strict;
use warnings;
use autodie;

my \$contents =
{
    'title' => \"My Lecture Title\",
    'subs' =>
    [
    ],
    'images' =>
    [
        'style.css',
    ],
};

sub get_contents
{
    return \$contents;
}

1;
EOF
    );

    path("$src_dir_name/template.wml")
        ->spew_raw("\n\n#include \"quadpres_main.wml\"\n\n");

    my $modules_dir = $self->path_man()->get_modules_dir();

    # Prepare the serve.pl file that can be used to serve it using a CGI;
    my $serve_filename = "$src_dir_name/serve.pl";
    path($serve_filename)->spew_raw(<<"EOF");
#!/usr/bin/env perl

use strict;
use warnings;

use lib '${modules_dir}';

use Shlomif::Quad::Pres::CGI ();

my \$cgi = Shlomif::Quad::Pres::CGI->new();

\$cgi->run();

EOF
    chmod 0755, $serve_filename;

    my $src = path("$src_dir_name/src");
    $src->mkpath();

    my $template_dir_path_str = $self->path_man()->get_template_dir();

    path("$template_dir_path_str/style.css")->copy( $src->child("style.css") );
    path( "$template_dir_path_str/template.html.wml", )
        ->copy("$src_dir_name/template.html.wml");

    # Create a file indicating that this is the root directory.
    # Regular named files may be present somewhere inside the ./src
    # directory for all we know.
    path("$src_dir_name/.quadpres")->mkpath();
    path("$src_dir_name/.quadpres/is_root")->spew_raw('');

    print "Successfully Created $src_dir_name\n";

    return 0;
}

sub chdir_to_base
{
    my $self = shift;

    my $current_path = cwd();
    my @path         = split( qr#/#, $current_path );

    my $levels_num = 0;

    # Go to the base dir.
    while ( not -e ".quadpres/is_root" )
    {
        chdir("..");
        ++$levels_num;
        if ( cwd() eq "/" )
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

sub _setup_cache
{
    my ( $self, $use_cache ) = @_;
    if ($use_cache)
    {
        if ( my $basedir = $ENV{QUAD_PRES_CACHE_DIR} )
        {
            $self->_cache_dir( $basedir . "/qp-pages/" . cwd() );
            $self->_all_in_one_cache_dir(
                $basedir . "/qp-all-in-one/" . cwd() );
        }
    }
    return;
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
    my $use_cache             = 0;

    $getopt->getoptionsfromarray(
        $cmd_line,
        'a|all!'        => \$render_all,
        'cache!'        => \$use_cache,
        'hd|hard-disk!' => \$render_hard_disk_html,
    );

    if ( !$render_all )
    {
        $error_class->throw(
            { text => "Don't know how to render anything but all yet.", } );
    }
    $self->_setup_cache($use_cache);

    $self->chdir_to_base();

    eval { $self->_render_all_contents(); };
    my $error = $@;
    if (   $error
        && blessed($error)
        && $error->isa('QuadPres::Exception::RenderFile') )
    {
        $error_class->throw( { text => "Rendering Failed!" } );
    }
    elsif ($error)
    {
        die $error;
    }

    if ($render_hard_disk_html)
    {
        $self->_convert_to_hardisk();
    }

    return 0;
}

sub _convert_to_hardisk
{
    my $self = shift;

    my $cfg = QuadPres::Config->new();

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

sub _iterate_branch_images
{
    my ( $self, $branch, $cb ) = @_;

    if ( exists( $branch->{'images'} ) )
    {
        foreach my $image_fn ( @{ $branch->{'images'} } )
        {
            $cb->( $image_fn, );
        }
    }
    return;
}

sub _render_all_contents_traverse_callback
{
    my ( $self, $args ) = @_;

    my @path     = @{ $args->{'path'} };
    my $branch   = $args->{'branch'};
    my $dest_dir = $self->dest_dir;
    my $src_dir  = $self->src_dir;

    my $p = join( "/", @path );

    my $is_dir       = exists( $branch->{'subs'} );
    my $filename     = "$dest_dir/$p";
    my $src_filename = "$src_dir/$p";

    if ($is_dir)
    {
        # It is a directory
        if ( !( -d $filename ) )
        {
            path($filename)->mkpath();
        }
        $filename     .= "/index.html";
        $src_filename .= "/index.html";
    }
    $src_filename .= ".wml";

    # Automatically copy the template to the source filename
    if ( not -e $src_filename )
    {
        if ($is_dir)
        {
            my $dir_name = $src_filename;
            $dir_name =~ s#/*index\.html\.wml\z##;
            path($dir_name)->mkpath();
        }
        path("template.html.wml")->copy($src_filename);
    }

    my $src_mtime  = $self->_get_file_mtime($src_filename);
    my $dest_mtime = $self->_get_file_mtime($filename);

    if (
        ( !-e $filename )
        || ( grep { $_ > $dest_mtime }
            ( @{ $self->main_files_mtimes() }, $src_mtime ) )
        )
    {
        my $src_filename_modified = $src_filename;
        $src_filename_modified =~ s#\A(\./)?src/*##;
        $self->_render_file(
            {
                input_fn  => $src_filename_modified,
                output_fn => $filename,
            },
        );
    }

    $self->_iterate_branch_images(
        $branch,
        sub {
            my ($image_fn)   = @_;
            my $filename     = "$dest_dir/$p/$image_fn";
            my $src_filename = "$src_dir/$p/$image_fn";

            if ( should_update( $filename, ":", $src_filename ) )
            {
                eval { copy_with_creating_dir( $src_filename, $filename ); };
                if (0)
                {
                    if ( my $E = $@ )
                    {
                        warn $E;
                    }
                }
            }
            return;
        },
    );

    return;
}

sub _mkpath_dir
{
    return path( shift @_ )->parent->mkdir();
}

my $QUAD_PRES_NO_HOME_LIB = ( !!$ENV{"QUAD_PRES_NO_HOME_LIB"} );
my $QUAD_PRES_QUIET       = ( !!$ENV{"QUAD_PRES_QUIET"} );

my $HOME = $ENV{"HOME"};

my $LOCAL_WML_DIR = "$HOME/.Quad-Pres/lib/";

my @LOCAL_WML =
    $QUAD_PRES_NO_HOME_LIB
    ? ()
    : ( "-I", $LOCAL_WML_DIR );

sub _render_file
{
    my ( $self, $args ) = @_;

    my $filename        = $args->{input_fn};
    my $output_filename = $args->{output_fn};

    $filename =~ s{\.wml\z}{};
    $filename =~ s{/\z}{/index.html};

    my $path_man = Shlomif::Quad::Pres::Path->new();

    my $wml_dir     = $path_man->get_wml_dir();
    my $modules_dir = $path_man->get_modules_dir();
    my $cache       = $self->_cache_dir;

    _mkpath_dir($output_filename);
    if ( $cache && -e "$cache/$filename" )
    {
        path("$cache/$filename")->copy($output_filename);
        return;
    }

    my @command = (
        "-I", $wml_dir, @LOCAL_WML, "-DFILENAME=$filename",
        "--passoption=3,-I$modules_dir",
        "-o", $output_filename, "src/$filename.wml"
    );

    if ( !$QUAD_PRES_QUIET )
    {
        print join( " ", 'wml', @command ), "\n";
    }

    my $ret = -1;

    eval { $ret = $self->_wml_obj->run_with_ARGV( { ARGV => [@command], } ); };
    my $Err = $@;

    # If it failed.
    if ( $Err or $ret != 0 )
    {
        # Clean-up the file so it will have to be regenerated
        my $error = QuadPres::Exception::RenderFile->new();
        $error->{'src_filename'} = $filename;
        die $error;
    }
    if ($cache)
    {
        my $cached_file_path = "$cache/$filename";

        _mkpath_dir($cached_file_path);
        path($output_filename)->copy($cached_file_path);
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
            my $error = QuadPres::Exception::RenderFile->new();
            $error->{'src_filename'} = $src_filename;
            die $error;
        }

=end

=cut

sub _assign_src_dir
{
    my $self = shift;

    my $src_dir = "./src/";

    if ( $src_dir !~ m#/\z# )
    {
        $src_dir .= "/";
    }

    $self->src_dir($src_dir);

    return;
}

sub _render_all_contents
{
    my ( $self, $dest_dir ) = @_;

    my $cfg = QuadPres::Config->new();

    my $default_dest_dir = $cfg->get_server_dest_dir();
    my $render_type      = "server";

    require Contents;
    my $contents = Contents::get_contents();

    $self->_assign_src_dir();

    $dest_dir ||= $default_dest_dir;
    if ( $dest_dir !~ m#/\z# )
    {
        $dest_dir .= "/";
    }
    $self->dest_dir($dest_dir);

    my $group    = $cfg->get_setgid_group();
    my $fs_iface = QuadPres::FS->new( 'group' => $group );

    # Check if the destination directory exists and if not -
    # create it.
    $fs_iface->make_dest_dir($dest_dir);

    $self->main_files_mtimes(
        [
            map { $self->_get_file_mtime($_) } ( "Contents.pm", "template.wml" )
        ]
    );

    my $quadpres_obj = QuadPres->new(
        $contents,
        'doc_id' => "/",
        'mode'   => "server",
    );

    $quadpres_obj->ref_traverse_tree(
        sub { $self->_render_all_contents_traverse_callback(shift) } );

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

    $getopt->getoptionsfromarray( $cmd_line, 'a|all!' => \$clear_all );

    if ( !$clear_all )
    {
        $error_class->throw(
            { text => q{Don't know how to clear anything but all yet.}, } );
    }

    # Go to the base dir.
    $self->chdir_to_base();

    my $cfg      = QuadPres::Config->new();
    my $dest_dir = $cfg->get_server_dest_dir();
    path($dest_dir)->remove_tree();

    return 0;
}

sub perform_upload_command
{
    my $self = shift;

    $self->chdir_to_base();

    my $cfg = QuadPres::Config->new();

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
    my ( $main_path, $last_component ) =
        ( $dest_dir =~ m{\A(.*?)/([^/]*)/*\z}ms );

    chdir($main_path);
    my @command;

    if ( $util eq "rsync" )
    {
        @command =
            ( qw(rsync --verbose -r), $last_component . "/", $upload_path );
    }
    elsif ( $util eq "scp" )
    {
        @command = ( qw(scp -r), $last_component . "/", $upload_path );
    }
    elsif ( $util eq "generic" )
    {
        my $cmd_line = $cfg->get_upload_cmdline();
        @command = split( /\s+/, $cmd_line );
        foreach my $c (@command)
        {
            $c =~ s/\$\{local\}/$last_component/g;
            $c =~ s/\$\{remote_path\}/$upload_path/g;
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
            { text => "Cannot add files outside the src directory", }, );
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
    my $last_component = $file_path->[-1];
    if ( $last_component !~ s/\.wml\z// )
    {
        $error_class->throw(
            {
                text => "The Filename \"$last_component\" is not a slide."
            }
        );
    }

    if ( ( grep { $_->{url} eq $last_component } @{ $current_section->{subs} } )
        || ( grep { $_ eq $last_component } @{ $current_section->{images} } ) )
    {
        $error_class->throw(
            {
                text => "The File already exists in the lecture.",
            }
        );
    }
    push @{ $current_section->{subs} },
        {
        url   => $last_component,
        title => "My Title",
        ( ( -d $filename ) ? ( subs => [] ) : () )
        };

    QuadPres::WriteContents->new( contents => $contents )->update_contents();

    return 0;
}

sub copy_with_creating_dir
{
    my ( $src_fn, $dest_fn ) = @_;
    _mkpath_dir($dest_fn);
    return path( $src_fn, )->copy($dest_fn);
}

sub _traverse_pack_copy_branch
{
    my ( $self, $path, $branch, ) = @_;

    my $is_dir = exists( $branch->{'subs'} );

    my $src_dir = $self->src_dir();

    my $filename = ( $self->src_archive_src_dir() . "/$path" );
    if ($is_dir)
    {
        # It is a directory
        if ( !( -d $filename ) )
        {
            path($filename)->mkpath();
        }
        my $target = "$filename/index.html.wml";
        path("$src_dir/$path/index.html.wml")->copy($target);
        $self->_set_time($target);
    }
    else
    {
        my $target = "$filename.wml";
        path("$src_dir/$path.wml")->copy($target);
        $self->_set_time($target);
    }
    return;
}

sub _traverse_pack_callback
{
    my ( $self, $args ) = @_;

    my $path   = join( "/", @{ $args->{'path'} } );
    my $branch = $args->{'branch'};

    $self->_traverse_pack_copy_branch( $path, $branch, );

    $self->_iterate_branch_images(
        $branch,
        sub {
            my ($image_fn)   = @_;
            my $suf          = "/$path/$image_fn";
            my $filename     = $self->src_archive_src_dir() . $suf;
            my $src_filename = $self->src_dir() . $suf;

            eval {
                copy_with_creating_dir( $src_filename, $filename );
                $self->_set_time($filename);
            };
            return;
        },
    );

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

    my $cfg = QuadPres::Config->new();

    $self->_assign_src_dir();

    my $src_archive_name__base = $cfg->get_src_archive_path()
        || ( $cfg->get_server_dest_dir() . "/src.tar" );

    path( $self->src_archive_dir() )->remove_tree();
    path( $self->src_archive_dir() )->mkpath();
    path( $self->src_archive_dir() . "/.quadpres" )->mkpath();

    # Copy the files from the root directory.
    foreach my $filename (
        sort { $a cmp $b }
        grep { -f $_ }
        map  { bsd_glob($_) }
        qw( *.pm *.wml *.html quadpres.ini *.pl *.sh .quadpres/* .wmlrc )
        )
    {
        my $target = $self->src_archive_dir() . "/$filename";
        path($filename)->copy($target);
        $self->_set_time($target);
    }

    path( $self->src_archive_src_dir() )->mkpath();

    require Contents;
    my $contents = Contents::get_contents();

    my $quadpres_obj = QuadPres->new(
        $contents,
        'doc_id' => "/",
        'mode'   => "server",
    );

    $quadpres_obj->ref_traverse_tree(
        sub {
            return $self->_traverse_pack_callback(shift);
        }
    );

    my $files = path( $self->src_archive_dir() )->visit(
        sub {
            my ( $path, $state ) = @_;
            return if $path->is_dir;
            $state->{$path} = 1;
        },
        { recurse => 1 }
    );

    system( "tar", "-cf", $src_archive_name__base,
        sort { $a cmp $b } keys %$files );
    eval { unlink("$src_archive_name__base.gz"); };
    system( "gzip", "--best", "-n", $src_archive_name__base );

    return 0;
}

sub _calc_page_id
{
    my $link_path = shift;

    my $ext = (
        ( @$link_path and ( $link_path->[-1] =~ s{\.html\z}{} ) )
        ? "PAGE"
        : "DIR"
    );
    return join( "--", "page", @$link_path, $ext, );
}

sub _render_to_all_in_one__helper
{
    my ( $self, $all_in_one_out_fh, $branch, $p, $dest_dir, $is_first,
        $direction, $path_aref, )
        = @_;

    my @path     = @{$path_aref};
    my $is_dir   = exists( $branch->{'subs'} );
    my $filename = ( "$dest_dir/$p" . ( $is_dir ? "/index.html" : '' ) );

    my $text = path($filename)->slurp_raw();

    if ( !$is_first )
    {
        $text =~ s{.*?(<header)}{$1}ms;
    }
    else
    {
        $text =~ s{<link rel="(?:top|next|first|last)".*?/>}{}gms;
        $text =~
s{\Q<!-- Beginning of Project Wonderful ad code: -->\E.*\Q<!-- End of Project Wonderful ad code. -->\E}{}ms;
        if ( $direction eq 'rtl' )
        {
            my $pivot = qq#dir="$direction"#;
            $text =~ s%(<html)([^>]+)(>)%
            my ($s, $m, $e) = ($1, $2, $3);
            $s . ($m =~ /$pivot/ ? $m : "$m $pivot") . $e%e;
        }
    }

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

        return "#" . _calc_page_id( [@link_path] );
    };

    # Fix the internal links
    $text =~ s{(<a href=")([^"]+)(")}
    {
        my ($s, $l, $e) = ($1, $2, $3);
        $s . $fix_internal_link->($l) . $e
    }egms
        ;

    my $div_tag = qq{<section class="page">\n};

    my $id_attr = qq{ id="} . _calc_page_id( [@path] ) . qq{"};

    if ( $text !~ s{(<body[^>]*>)}{$1$div_tag}ms )
    {
        $text = $div_tag . $text;
    }

    $text =~ s{<h1>}{<h2$id_attr>};
    $text =~ s{</h1>}{</h2>};
    $text =~ s%</?main>%%g;
    $text =~ s%(<table(?:\s+(?:class|style)="[^"]*"\s*)*) summary=""%$1%g;

    print {$all_in_one_out_fh} $text, qq{\n</section>\n};

    return;
}

sub perform_render_all_in_one_page_command
{
    my $self = shift;

    my $cmd_line = $self->cmd_line();
    my $getopt   = $self->getopt();

    if ( !@$cmd_line )
    {
        $error_class->throw(
            { text => 'render must be followed by filenames or flags' } );
    }

    my $all_in_one_dir;
    my $direction = 'ltr';
    my $use_cache = 0;
    $getopt->getoptionsfromarray(
        $cmd_line,
        'cache!'       => \$use_cache,
        'output-dir=s' => \$all_in_one_dir,
        'html-dir=s'   => \$direction,
    );
    if ( !defined $all_in_one_dir )
    {
        $error_class->throw( { text => 'please specify an --output-dir.', } );
    }
    $self->_setup_cache($use_cache);

    require Contents;
    my $contents = Contents::get_contents();

    my $cfg = QuadPres::Config->new();

    my $dest_dir = $cfg->get_server_dest_dir();
    if ( $dest_dir !~ m{/\z} )
    {
        $dest_dir .= "/";
    }

    my $group = $cfg->get_setgid_group();

    my $quadpres_obj = QuadPres->new(
        $contents,
        'doc_id' => "/",
        'mode'   => "server",
    );

    if ( !-d $all_in_one_dir )
    {
        path($all_in_one_dir)->mkpath();
    }
    my $_cache_dir = $self->_all_in_one_cache_dir;
    my $_cache_fn;
    if ( defined $_cache_dir )
    {
        path($_cache_dir)->mkpath();
        $_cache_fn = "$_cache_dir/all_in_one.html";
    }
    my $all_fn = "$all_in_one_dir/index.html";
    my $all_in_one_out_fh;
    if ( ( defined $_cache_fn ) && ( -f $_cache_fn ) )
    {
        path($_cache_fn)->copy($all_fn);
    }
    else
    {
        open $all_in_one_out_fh, ">", $all_fn;
    }

    my $is_first              = 1;
    my $_render_to_all_in_one = sub {
        my ($args) = @_;

        my @path   = @{ $args->{'path'} };
        my $branch = $args->{'branch'};

        my $p = join( "/", @path );

        if ( defined $all_in_one_out_fh )
        {
            $self->_render_to_all_in_one__helper( $all_in_one_out_fh, $branch,
                $p, $dest_dir, $is_first, $direction, \@path, );
            $is_first = 0;
        }
        $self->_iterate_branch_images(
            $branch,
            sub {
                my ($image_fn)    = @_;
                my $suf           = "/$p/$image_fn";
                my $src_filename  = $dest_dir . $suf;
                my $dest_filename = $all_in_one_dir . $suf;

                if ( should_update( $dest_filename, ":", $src_filename ) )
                {
                    eval {
                        copy_with_creating_dir( $src_filename, $dest_filename );
                    };
                }
                return;
            },
        );
        return;
    };

    $quadpres_obj->ref_traverse_tree( $_render_to_all_in_one, );

    if ( defined $all_in_one_out_fh )
    {
        print {$all_in_one_out_fh} "\n</body></html>\n";
        close($all_in_one_out_fh);

        if ( defined $_cache_dir )
        {
            path($all_fn)->copy($_cache_fn);
        }
    }

    return 0;
}

1;
