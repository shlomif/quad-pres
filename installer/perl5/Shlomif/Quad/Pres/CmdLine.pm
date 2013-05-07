package Shlomif::Quad::Pres::CmdLine;

use strict;
use warnings;

use Scalar::Util qw(blessed);

use Shlomif::Gamla::Object;

use vars qw(@ISA);

@ISA=qw(Shlomif::Gamla::Object);

use English;
use Pod::Usage;
use Cwd;
use Data::Dumper;
use File::Copy;
use File::Path ();
use File::Basename;
use Carp;
use File::Spec;
use HTML::Links::Localize;
use File::Glob ':glob';

use Shlomif::Quad::Pres::Path;
use Shlomif::Quad::Pres::Exception;
use Shlomif::Quad::Pres::Getopt;
use Shlomif::Quad::Pres::Config;
use Shlomif::Quad::Pres;
use Shlomif::Quad::Pres::FS;
use Shlomif::Quad::Pres::WriteContents;

use Moose qw(has);

has 'dest_dir' => (isa => 'Str', 'is' => 'rw');
has 'src_dir' => (isa => 'Str', 'is' => 'rw');
has 'main_files_mtimes' => (isa => 'ArrayRef', 'is' => 'rw');
has 'path_man' => (isa => "Shlomif::Quad::Pres::Path", 'is' => "rw");
has 'getopt' => (isa => "Shlomif::Quad::Pres::Getopt", 'is' => "rw");
has 'cmd_line' => (isa => "ArrayRef", 'is' => "rw");
has 'invocation_path' => (isa => "ArrayRef", is => "rw");

my $error_class = "Shlomif::Quad::Pres::Exception";


sub initialize
{
    my $self = shift;

    $self->path_man(Shlomif::Quad::Pres::Path->new());

    my (%args);

    %args = (@_);

    $self->_init_cmd_line($args{'cmd_line'});

    return 0;
}

sub _init_cmd_line
{
    my ($self, $cmd_line) = @_;

    if (!defined($cmd_line))
    {
        $error_class->throw({text => 'cmd_line not specified'});
    }

    $self->cmd_line($cmd_line);

    $self->getopt(
        Shlomif::Quad::Pres::Getopt->new($cmd_line)
    );

    return;
}

sub gen_aliases
{
    my $command = shift;
    my $aliases = shift;

    return (map { $_ => $command } ($command, @$aliases));
}

my %cmd_aliases;

my %registered_commands;

sub reg_cmd
{
    my $command = shift;
    my $callback = shift || "perform_${command}_command";
    my $aliases = shift || [];
    %cmd_aliases = (%cmd_aliases, gen_aliases($command, $aliases));
    $registered_commands{$command} = $callback;
}

reg_cmd('clear');
reg_cmd('render',0,[qw(rend)]);
reg_cmd('setup');
reg_cmd('upload');
reg_cmd('add');
reg_cmd('pack');

sub run_command
{
    my $self = shift;

    my %args = (@_);

    my $command = $args{command};
    my $error_text = $args{error_text};

    my $cmd_ret;

    if (ref($command) eq "ARRAY")
    {
        $cmd_ret = system(@$command);
    }
    else
    {
        $cmd_ret = system($command);
    }

    if ($cmd_ret != 0)
    {
        $error_class->throw({text => $error_text});
    }

    return 0;
}


sub run
{
    my $self = shift;

    my $ret;
    eval {
        $ret = $self->real_run();
    };

    if (my $E = $@)
    {
        if (blessed($E) && $E->isa($error_class))
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

    my ($help, $man);

    my $getopt = $self->getopt();

    $getopt->configure('require_order');
    $getopt->getoptions(
        'help|h|?' => \$help,
        'man' => \$man,
    ) or pod2usage(2);

    pod2usage(1) if $help;
    pod2usage(-exitstatus => 0, -verbose => 2) if $man;

    my $command = $self->_get_cl_param({'empty_cb' => sub { pod2usage(1) },},);

    if (! exists($cmd_aliases{$command}))
    {
        $error_class->throw({text => "Unknown Command \"$command\"!"});
    }

    my $callback = $registered_commands{$cmd_aliases{$command}};

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
    my ($self, $args) = @_;

    if (! @{$self->cmd_line()})
    {
        if (exists($args->{empty_cb}))
        {
            return $args->{empty_cb}->();
        }
        $error_class->throw({text => $args->{error_text} });
    }

    return shift(@{$self->cmd_line()});
}

sub perform_setup_command
{
    my $self = shift;

    my $getopt = $self->getopt();

    my $src_dir_name = $self->_get_cl_param({'error_text' => "setup must be followed by a directory name"});

    my %args =
    (
        "server_dest_dir" => undef,
        "setgid_group" => "",
        "upload_path" => "",
    );

    $getopt->getoptions(
        'dest-dir=s' => \$args{"server_dest_dir"},
        'setgid-group=s' => \$args{"setgid_group"},
        'upload-path=s' => \$args{"upload_path"},
    );

    if (!defined($args{"server_dest_dir"}))
    {
        $error_class->throw(
            {text => 'You must specify --dest-dir with somthing meaningful!'}
        );
    }

    if (! mkdir($src_dir_name) )
    {
        $error_class->throw({
                text => "Could not create the source directory.\nErrno=$!"
            }
        );
    }

    open INI, ">$src_dir_name/quadpres.ini";

    my $print_section = sub {
        my $section = shift;
        my $which_args = shift;

        print INI "[$section]\n\n";

        foreach my $arg (@$which_args)
        {
            print INI "$arg=" . $args{$arg}. "\n\n";
        }
    };

    my $src_dir_path = get_dir_path($src_dir_name);

    print INI <<"EOF" ;
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
    ;

    close INI;

    open WMLRC, ">$src_dir_name/.wmlrc";

    print WMLRC "-DROOT~src --passoption=2,-X3074 -DTHEME=shlomif-text\n";

    close WMLRC;

    open O, ">$src_dir_name/Contents.pm";

    print O
        ("package Contents;\n\n",
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
        );

    close(O);

    open TEMPLATE, ">$src_dir_name/template.wml";
    print TEMPLATE "\n\n#include \"quadpres_main.wml\"\n\n";
    close TEMPLATE;

    my $modules_dir = $self->path_man()->get_modules_dir();

    # Prepare the serve.pl file that can be used to serve it using a CGI;
    my $serve_filename = "$src_dir_name/serve.pl";
    open SERVE, ">".$serve_filename;
    print SERVE <<"EOF";
#!/usr/bin/perl -w -I$modules_dir

use strict;
use Shlomif::Quad::Pres::CGI;

my \$cgi = Shlomif::Quad::Pres::CGI->new();

\$cgi->run();

EOF
    ;
    close SERVE;
    chmod 0755, $serve_filename;

    mkdir("$src_dir_name/src");

    my $template_dir = $self->path_man()->get_template_dir();

    copy("$template_dir/style.css", "$src_dir_name/src/style.css");
    copy("$template_dir/template.html.wml", "$src_dir_name/template.html.wml");

    # Create a file indicating that this is the root directory.
    # Regular named files may be present somewhere inside the ./src
    # directory for all we know.
    mkdir ("$src_dir_name/.quadpres");
    open O, ">$src_dir_name/.quadpres/is_root";
    print O "";
    close(O);

    print "Successfully Created $src_dir_name\n";

    return 0;
}

sub chdir_to_base
{
    my $self = shift;

    my $current_path = getcwd();
    my @path = split(/\//, $current_path);

    my $levels_num = 0;

    # Go to the base dir.
    while (! -e ".quadpres/is_root")
    {
        chdir("..");
        $levels_num++;
        if (getcwd() eq "/")
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
        [ @path[(scalar(@path)-$levels_num) .. $#path ] ]
    );

    return 0;
}

sub perform_render_command
{
    my $self = shift;

    my $cmd_line = $self->cmd_line();
    my $getopt = $self->getopt();

    if (! @$cmd_line)
    {
        $error_class->throw(
            { text => 'render must be followed by filenames or flags' }
        );
    }

    my $render_all = 0;
    my $render_hard_disk_html = 0;

    $getopt->getoptions(
        'a|all!' => \$render_all,
        'hd|hard-disk!' => \$render_hard_disk_html,
    );

    if (! $render_all)
    {
        $error_class->throw(
            { text => "Don't know how to render anything but all yet.", }
        );
    }

    $self->chdir_to_base();

    eval {
    $self->_render_all_contents();
    };
    my $error = $@;
    if ($error && blessed($error) && $error->isa('Shlomif::Quad::Pres::Exception::RenderFile'))
    {
        $error_class->throw({text => "Rendering Failed!"});
    }

    # $self->run_command(
    #     'command' => "$scripts_dir/Render_all_contents.pl",
    #     'error_text' => "Rendering Failed!",
    # );

    if ($render_hard_disk_html)
    {
        $self->_convert_to_hardisk()
    }

    return 0;
}

sub _convert_to_hardisk
{
    my $self = shift;

    my $cfg = Shlomif::Quad::Pres::Config->new();

    my $default_dest_dir = $cfg->get_server_dest_dir();

    my $hard_disk_dest_dir = $cfg->get_hard_disk_dest_dir();

    my $converter=
        HTML::Links::Localize->new(
            'base_dir' => $default_dest_dir,
            'dest_dir' => $hard_disk_dest_dir,
        );

    $converter->process_dir_tree('only-newer' => 1);
}

sub _get_file_mtime
{
    my ($self,$path) = @_;

    return (stat($path))[9];
}

sub _render_all_contents_traverse_callback
{
    my $self = shift;
    my (%arguments) = (@_);

    my $path_ref = $arguments{'path'};
    my $branch = $arguments{'branch'};

    my (@path);

    @path = @{$path_ref};

    my $p = join("/", @path);

    {
        my ($filename, $src_filename);

        my $is_dir = exists($branch->{'subs'});

        my $src_dir = $self->src_dir();

        if ($is_dir)
        {
            # It is a directory
            $filename = ($self->dest_dir() . "/" . $p);
            if (! (-d $filename))
            {
                mkdir($filename);
            }
            $filename .= "/index.html";
            $src_filename = $src_dir . "/" . $p . "/index.html";
        }
        else
        {
            $filename = ($self->dest_dir() . "/" . $p);
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

        {
            my $src_mtime = $self->_get_file_mtime($src_filename);
            my $dest_mtime = $self->_get_file_mtime($filename);

            if ((! -e $filename) ||
                (grep
                    { $_ > $dest_mtime }
                    (@{$self->main_files_mtimes()},$src_mtime)
                ))
            {
                my $src_filename_modified = $src_filename;
                $src_filename_modified =~ s/^(\.\/)?src\/*//;
                $self->_render_file(
                    {
                        input_fn => $src_filename_modified,
                        output_fn => $filename,
                    },
                );
            }
        }
    }


    if (exists($branch->{'images'}))
    {
        foreach my $image (@{$branch->{'images'}})
        {
            my $filename = $self->dest_dir() . "/" . $p . "/" . $image ;
            my $src_filename = $self->src_dir() . "/" . $p . "/" . $image ;

            my $src_mtime = $self->_get_file_mtime($src_filename);
            my $dest_mtime = $self->_get_file_mtime($filename);

            if ((! -e $filename) ||
                ($src_mtime > $dest_mtime)
                )
            {
                copy_with_creating_dir($src_filename, $filename);
            }
        }
    }
}

sub _render_file
{
    my ($self, $args) = @_;

    my $filename = $args->{input_fn};
    my $output_filename = $args->{output_fn};

    $filename =~ s{\.wml$}{};
    $filename =~ s{/$}{/index.html};

    my $path_man = Shlomif::Quad::Pres::Path->new();

    my $wml_dir = $path_man->get_wml_dir();
    my $modules_dir = $path_man->get_modules_dir();

    my $local_wml_dir = $ENV{"HOME"}. "/.Quad-Pres/lib/";

    my @local_wml =
        $ENV{"QUAD_PRES_NO_HOME_LIB"}
            ? ()
            : ("-I", $local_wml_dir)
        ;

    my @command = (
        "wml",
        "-I", $wml_dir,
        @local_wml,
        "-DFILENAME=$filename",
        "--passoption=3,-I$modules_dir",
        "-o", $output_filename,
        "src/$filename.wml"
    );

    if (! $ENV{"QUAD_PRES_QUIET"})
    {
        print join(" ", @command), "\n";
    }

    my $ret = system(@command);

    # If it failed.
    if ($ret != 0)
    {
        # Clean-up the file so it will have to be regenerated
        my $error = Shlomif::Quad::Pres::Exception::RenderFile->new();
        $error->{'src_filename'} = $filename;
        die $error;
    }
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

    if ($src_dir !~ /\/$/)
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
    my $render_type = "server";

    require Contents;
    my $contents = Contents::get_contents();

    $self->_assign_src_dir();

    my $dest_dir = shift || $default_dest_dir;


    if ($dest_dir !~ /\/$/)
    {
        $dest_dir .= "/";
    }

    $self->dest_dir($dest_dir);

    my $group = $cfg->get_setgid_group();

    my $fs_iface = Shlomif::Quad::Pres::FS->new('group' => $group);

    # Check if the destination directory exists and if not -
    # create it.
    $fs_iface->make_dest_dir($dest_dir);

    my $render_all = 0;

    $self->main_files_mtimes([map { $self->_get_file_mtime($_) } ("Contents.pm", "template.wml")]);

    my $quadpres_obj =
        Shlomif::Quad::Pres->new(
            $contents,
            'doc_id' => "/",
            'mode' => "server",
        );

    $quadpres_obj->traverse_tree(sub {$self->_render_all_contents_traverse_callback(@_)});
}

sub perform_clear_command
{
    my $self = shift;

    my $cmd_line = $self->cmd_line();
    my $getopt = $self->getopt();

    if (! @$cmd_line)
    {
        $error_class->throw(
            {text => 'clear must be followed by filenames or flags',}
        );
    }

    my $clear_all = 0;

    $getopt->getoptions(
        'a|all!' => \$clear_all
    );

    if (! $clear_all)
    {
        $error_class->throw(
            {text => q{Don't know how to clear anything but all yet.},}
       );
    }

    # Go to the base dir.
    $self->chdir_to_base();

    my $cfg = Shlomif::Quad::Pres::Config->new();

    my $dest_dir = $cfg->get_server_dest_dir();

    File::Path::rmtree([$dest_dir], 0, 0);

    return 0;
}

sub perform_upload_command
{
    my $self = shift;

    $self->chdir_to_base();

    my $cfg = Shlomif::Quad::Pres::Config->new();

    my $util = $cfg->get_upload_util();

    if (!defined($util))
    {
        confess "The upload utility was not specified in the quadpres.ini file. Aborting.";
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
            qw(rsync --progress --verbose --rsh=ssh -a),
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
        confess "The upload utility is unrecognized by Quad Pres.";
    }

    print (join(" ", @command), "\n");
    return system(@command);
}

sub add_filename_to_path
{
    my $self = shift;

    my $orig_path = shift;
    my @path = @$orig_path;

    my $filename = shift;

    my @fn_path = split(/\//, $filename);

    foreach my $component (@fn_path)
    {
        if ($component eq ".")
        {
            next;
        }
        if ($component eq "..")
        {
            if (! @path)
            {
                $error_class->throw(
                    {
                        text =>
                        ('Path given exits from the lecture source'
                        . ' code base directory'),
                    }
                );
            }
            else
            {
                pop(@path);
            }
            next;
        }
        push(@path, $component);
    }

    return \@path;
}

sub perform_add_command
{
    my $self = shift;

    my $cmd_line = $self->cmd_line();

    $self->chdir_to_base();

    my $filename =
        $self->_get_cl_param({'error_text' => "add needs a filename"});

    my @path = @{$self->invocation_path()};

    my $file_path = $self->add_filename_to_path(\@path, $filename);

    if ($file_path->[0] ne "src")
    {
        $error_class->throw(
            {text => "Cannot add files outside the src directory",},
        );
    }

    # Remove "src" from the file path
    shift(@$file_path);

    $filename = join("/", "src", @$file_path);

    if (! -e $filename)
    {
        $error_class->throw({
                text => "File \"$filename\" does not exist"
            }
        );
    }

    require Contents;

    my $contents = Contents::get_contents();

    my $current_section = $contents;

    foreach my $component (@$file_path[0 .. ($#$file_path-1)])
    {
        my $next_section;
        SUB_SECT_SEARCH: foreach my $sub_sect (@{$current_section->{'subs'}})
        {
            if ($sub_sect->{'url'} eq $component)
            {
                $next_section = $sub_sect;
                last SUB_SECT_SEARCH;
            }
        }
        if (!defined($next_section))
        {
            $error_class->throw(
                {
                    text => ("Could not find the relevant section in "
                        . "the lecture's table of contents"
                    )
                }
            );
        }
        $current_section = $next_section;
    }
    my $last_component = $file_path->[$#$file_path];
    if ($last_component !~ /\.wml$/)
    {
        $error_class->throw({
                text => "The Filename \"$last_component\" is not a slide."
            }
        );
    }
    $last_component =~ s/\.wml$//;
    if ( (grep { $_->{'url'} eq $last_component } @{$current_section->{'subs'}})
       || (grep { $_ eq $last_component } @{$current_section->{'images'}}))
    {
        $error_class->throw(
            {
                text => "The File already exists in the lecture.",
            }
        );
    }
    my $is_dir = (-d $filename);
    my $title = "My Title";
    push @{$current_section->{'subs'}},
        {
            'url' => $last_component,
            'title' => $title,
            ($is_dir ? ('subs' => []) : ())
        };

    my $writer =
        Shlomif::Quad::Pres::WriteContents->new(contents => $contents);
    $writer->update_contents();

    return 0;
}

sub copy_with_creating_dir
{
    my ($src_fn, $dest_fn) = @_;
    File::Path::mkpath([dirname($dest_fn)]);
    return copy($src_fn, $dest_fn);
}

sub _traverse_pack_callback
{
    my $self = shift;

    my (%arguments) = (@_);

    my $path_ref = $arguments{'path'};
    my $branch = $arguments{'branch'};

    my (@path);

    @path = @{$path_ref};

    my $p = join("/", @path);

    {
        my ($filename, $src_filename);

        my $is_dir = exists($branch->{'subs'});

        my $src_dir = $self->src_dir();

        if ($is_dir)
        {
            # It is a directory
            $filename = ($self->src_archive_src_dir() . "/" . $p);
            if (! (-d $filename))
            {
                mkdir($filename);
            }
            copy($src_dir . "/" . $p . "/index.html.wml",
                 "$filename/index.html.wml"
            );
        }
        else
        {
            $filename = ($self->src_archive_src_dir() . "/" . $p);
            $src_filename = $src_dir . "/" . $p;
            copy($src_filename.".wml", $filename.".wml");
        }
    }


    if (exists($branch->{'images'}))
    {
        foreach my $image (@{$branch->{'images'}})
        {
            my $filename = $self->src_archive_src_dir() . "/" . $p . "/" . $image ;
            my $src_filename = $self->src_dir() . "/" . $p . "/" . $image ;

            File::Path::mkpath([dirname($filename)]);
            copy_with_creating_dir($src_filename, $filename);
        }
    }
}

sub src_archive_dir
{
    my $self = shift;

    return "./SOURCE";
}

sub src_archive_src_dir
{
    my $self = shift;

    return $self->src_archive_dir()."/src";
}

sub perform_pack_command
{
    my $self = shift;

    my $cfg = Shlomif::Quad::Pres::Config->new();

    $self->_assign_src_dir();

    my $src_archive_name = $cfg->get_src_archive_path() ||
        ($cfg->get_server_dest_dir() . "/" . "src.tar.gz");

    File::Path::rmtree([$self->src_archive_dir()], 0, 0);

    mkdir($self->src_archive_dir());
    mkdir($self->src_archive_dir(). "/.quadpres");

    # Copy the files from the root directory.
    foreach my $file (
        sort { $a cmp $b }
        grep { -f $_ }
        map { glob($_) }
        qw(*.pm *.wml *.html quadpres.ini *.pl *.sh .quadpres/* .wmlrc)
    )
    {
        copy($file, $self->src_archive_dir() . "/$file");
    }

    mkdir($self->src_archive_src_dir());


    require Contents;
    my $contents = Contents::get_contents();

    my $quadpres_obj =
        Shlomif::Quad::Pres->new(
            $contents,
            'doc_id' => "/",
            'mode' => "server",
        );

    $quadpres_obj->traverse_tree(
        sub {
            return $self->_traverse_pack_callback(@_);
        }
    );

    system("tar", "-czf", $src_archive_name, $self->src_archive_dir());

    return 0;
}

1;

