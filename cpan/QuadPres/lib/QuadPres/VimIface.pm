package QuadPres::VimIface;

use 5.016;
use strict;
use warnings;
use autodie;

use Text::VimColor ();
use Path::Tiny     qw/ path /;

sub _is_newer
{
    my $file1 = shift;
    my $file2 = shift;
    my @stat1 = stat($file1);
    my @stat2 = stat($file2);
    if ( !@stat2 )
    {
        return 1;
    }
    return ( $stat1[9] >= $stat2[9] );
}

sub get_syntax_highlighted_html_from_file
{
    my ($args) = @_;

    my $filename = $args->{'filename'};

    my $html_filename = "$filename.html-for-quad-pres";

    if ( _is_newer( $filename, $html_filename ) )
    {
        my $syntax = Text::VimColor->new(
            file           => $filename,
            html_full_page => 1,
            ( $args->{'filetype'} ? ( filetype => $args->{'filetype'} ) : () ),
        );

        path($html_filename)
            ->spew( $syntax->html =~ s#(<meta[^/>]+[^/])>#$1/>#gr );
    }

    my $text = path($html_filename)->slurp;

    $text =~ s{\A.*<pre>[\s\n\r]*}{}s;
    $text =~ s{[\s\n\r]*</pre>.*\z}{}s;
    $text =~ s{(class=")syn}{$1}g;

    return $text;
}

1;

__END__

=encoding utf8

=head1 NAME

QuadPres::VimIface - Vim syntax highlighting interface.

=head1 SYNOPSIS

    use QuadPres::VimIface ();
    my $code = QuadPres::VimIface::get_syntax_highlighted_html_from_file({filename=>"foo.pl"});

=head1 DESCRIPTION

Vim syntax highlighting interface.

=head1 FUNCTIONS

=head2 get_syntax_highlighted_html_from_file({filename=>$filepath, filetype=>"c",});

TBD.

=head2

=cut


=head1 COPYRIGHT & LICENSE

Copyright 2018 by Shlomi Fish

This program is distributed under the MIT / Expat License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
