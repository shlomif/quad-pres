#!/usr/bin/perl -w -I{QP_MODULES_DIR}

use strict;

use Shlomif::Quad::Pres::CmdLine;

my $cmd_line = 
    Shlomif::Quad::Pres::CmdLine->new(
        'cmd_line' => [@ARGV],
        );

exit($cmd_line->run());

__END__

=head1 NAME

quadp - the Quad-Pres Interface

=head1 SYNOPSIS

B<quadp> I<command> [options] arguments

(B<quadp> B<--man> displays the man page)

=head1 DESCRIPTION

This program serves as the command line front-end for all the quad-pres
functions. Its first argument is mandatory and is the command to execute.
The other arguments are command line options that are passed to it.

The available commands are:

=over 8

=item setup

Create a new lecture directory.

=item render

Render slides.

=item clear

Clear the rendered slides.

=item upload

Upload the rendered slides to a remote server.

=back 

=head1 COMMANDS

=head2 SETUP

This command's synopsis is as following:

B<quadp> B<setup> I<dir> I<[options]>

I<dir> is the directory in which to place the skeleton of a presentation.

It accepts the following options:

=over 8

=item --dest-dir=[dir] (Mandatory)

Sets B<[dir]> to be the destination directory of the slideshow. This is where
the rendered slides will be placed in.

=item --setgid-group=[group]

Specifies a group ID to make the root directory (and subsequent direcories)
SGID to. 

=item --upload-path=[path]

Specifies a path to upload the files to using scp, rsync, etc.

=back

You can later edit these settings by editing the B<quadpres.ini> file.

=head2 RENDER

The synopsis is as follows:

B<quadp> B<render> I<-a> [ I<--hd> | I<--hard-disk> ]

This command causes all the files to be rendered.

If a I<--hd> or I<--hard-disk> is appended, it also renders a tree of files
that are viewable from the hard disk without a web-server.

=head2 CLEAR

The synopsis is as follows:

B<quadp> B<clear> I<-a>

This command causes all the rendered files to be deleted.

=head2 UPLOAD

The synoposis is as follows:

B<quadp> B<upload>

This command uploads the rendered slides to the remote server.

=head1 The Contents.pm File

The Contents.pm file contains the layout of the lecture. It is a Perl 5
module that contains a nested data structure named C<$contents>. This data
strucutre maps to sections and sub-sections of the lecture which are placed
inside directories and sub-directories.

Each section is a hash reference that contains the following fields:

=over 8

=item 'url'

This is the relative URL of the section. It must be unique for every section.

=item 'title'

This is the title of this section.

=item 'subs'

This maps into a reference to an array of sub-sections.

=item 'images'

An optional reference to an array of files that will be copied as is and
won't be processed by Quad-Pres.

=back

An individual page without any sub-sections does not contain the C<'subs'>
and C<'images'> keys.

Here's an example:

    my $contents =
    {
        'title' => "My Lecture Title",
        'subs' =>
        [
            {
                'url' => "first",
                'title' => "First Section",
                'subs' =>
                [
                    {
                        'url' => "page1.html",
                        'title' => "First Subpage",
                    },
                ],
                'images' => [ 'hello.png' ],
            },
            {
                'url' => "second.html",
                'title' => "Second Page",
            },
        ],
        'images' =>
        [
            'style.css',
        ],
    };

The first section would have the relative URL C<first/> and the first
subpage the relativel URL C<first/page1.html>. There is an image 
C<first/hello.png>

=head1 Format of the template.wml file

The template.wml file is the master Web Meta Language template file for the 
slides. Within it one can put definitions of macros that are used in several
slides of the lecture. The file contains one statement:

    #include "quadpres_main.wml"

This makes sure all the slides will have a common look and feel, as well
as have several pre-defined WML macros that ship with quad pres.

Before this statement, one can put defaults for the page. To do so, put
the following statement at the beginning of the file:

    #include "wml_helpers.wml"

And then use the C<<< <default-var / > >>> statement to issue a default
for it. Available defaults include:

=over 8

=item qp_lang

The XML language for the file. Defaults to en-US

=item qp_charset

The XML/HTML character set for the file. Defaults to iso8859-1.

=item qp_body_dir

Whether the body directory is Left-to-Right (LTR) or Right-to-Left (RTL).
Set to either C<ltr> or C<rtl>. Default is C<ltr>

=item qp_doctype_strictnesss

Whether the file is XHTML 1.0 Strict or XHTML 1.0 Transitional. Set to 
either C<strict> or something else. Default is C<strict>

=back

Here's an example for a C<template.wml> file that sets some parameters:

    #include "wml_helpers.wml"
    <default-var "qp_lang" "fr-FR" />
    <default-var "qp_charset" "utf-8" />
    
    #include "quadpres_main.wml"

The C<$translate_control_text> is a reference to a Perl subroutine that
can be used to translate the labels on the controls. It accepts a single
string of the values C<"Next">, C<"Prev">, C<"Up"> or C<"Contents"> and
should return the translated value.

=head1 Format of an Individual Page

The first statement in a page should be 

    #include 'template.wml'

Afterwards one can put the HTML markup placed inside the slide.. Use the 
C<E<lt>qpcontents /E<gt>> tag to denote a table of contents for inside this 
sub-section onwards.

Beforehand this initial statement one can put settings for the page in a 
similar fashion described in the section "Format of the template.wml file".

=head1 Choosing a Theme

Quad-Pres ships with various themes that can modify its look and feel.
To set a theme for the lecture, edit the C<.wmlrc> file in the 
presentation's directory and change the C<-DTHEME=shlomif-text> directive
to define some other theme. Look in the Quad-Pres installation directory
under C<share/quad-pres/wml/themes> for a list of themes. (each theme is 
a directory there).

More themes can be created on your own based on the examples there.

=head1 quadpres.ini

The file C<quadpres.ini> is a standard INI file. However if there is a 
configuration option that starts with the prefix C<tt_> it is interpreted
as a small Template Toolkit template, whose value overrides that of the
normal non-C<tt_>'ed value.

=head2 Pre-defined Template Variables

Currently only the C<ENV> variable is defined as a hash containing the
environment variables. 

=head1 SEE ALSO

The Quad-Pres Homepage:

L<http://vipe.technion.ac.il/~shlomif/quadpres/>

=head1 AUTHOR

Shlomi Fish E<lt>F<shlomif@vipe.technion.ac.il>E<gt>

=cut
