#!/usr/bin/perl -w

use strict;

use File::Copy;

use XML::LibXML;

my $files_or_dirs = shift || "-f";

$files_or_dirs = ($files_or_dirs eq "-f");

my $source_dir = shift || ".";

my (@dirs, @files);
sub process_dir
{
    my $dir = shift;

    my $dir_slash = ($dir eq "") ? "" : "$dir/";

    if ($dir ne "")
    {
        push @dirs, $dir;
    }

    my (@entries);
    
    {
        my $parser = XML::LibXML->new();

        my $dom = $parser->parse_file("$source_dir/${dir_slash}.svn/entries");

        my @svn_entries = $dom->getDocumentElement()->getChildrenByTagName("entry");

        foreach (@svn_entries)
        {
            my $deleted = $_->getAttribute("deleted");
            if (defined($deleted) && ($deleted eq "true"))
            {
                next;
            }
            if ($_->hasAttribute("url"))
            {
                next;
            }

            push @entries, $_->getAttribute("name");
        }
    }

    foreach my $entry (@entries)
    {
        my $rel_path = "${dir_slash}$entry";
        my $full_path = "$source_dir/$rel_path";
        if (-d $full_path)
        {
            process_dir($rel_path);
        }
        else
        {
            push @files, $rel_path;
        }
    }    
}

process_dir("");

print map { "$_\n" } (($files_or_dirs) ? (@files) : (@dirs));

