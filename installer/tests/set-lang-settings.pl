#!/usr/bin/perl -w

use strict;

my ($dir, $global_lang, $global_charset, $local_lang, $local_charset) = @ARGV;

sub add_header
{
    my $filename = shift;
    my $header = shift;

    open I, "<$filename";
    my $text = join("",<I>);
    close(I);

    open O, ">$filename";
    print O "$header\n$text";
    close(O);
}

my $total_lang = "en-US";
my $total_charset = "iso-8859-1";

sub get_header
{
    my $lang = shift;
    my $charset = shift;

    if ($lang)
    {
        $total_lang = $lang;
    }
    if ($charset)
    {
        $total_charset = $charset;
    }

    return "#include \"wml_helpers.wml\"\n" . 
            ($lang ? 
                "<default-var \"lang\" \"$lang\" />\n" : 
                ""
            ) .
            ($charset ? 
                "<default-var \"charset\" \"$charset\" />\n" : 
                ""
            );
}

if ($global_lang || $global_charset)
{
    add_header(
        "$dir/template.wml", 
        get_header($global_lang, $global_charset),
        );
}

if ($local_lang || $local_charset)
{
    add_header(
        "$dir/src/index.html.wml", 
        get_header($local_lang, $local_charset),
        );    
}

print "$total_charset $total_lang\n";

