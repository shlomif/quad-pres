#!/usr/bin/perl -w

use strict;

use File::Copy;

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

    open I, "<$source_dir/${dir_slash}.svn/entries" or
        die "Cannot open \"$source_dir/${dir_slash}.svn/entries\"" ;

    my (@entries);
    while (<I>)
    {
        if (/name=\"([^\"]*)\"/)
        {
            my $filename = $1;
            if ($filename ne "svn:this_dir")
            {
                push @entries, $filename;
            }
        }
    }
    close(I);

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

