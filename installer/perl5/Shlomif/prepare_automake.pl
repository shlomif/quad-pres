#!/usr/bin/perl -w

use strict;

use File::Find;

my @dirs;

sub wanted
{
    my $filename = $File::Find::name;
    if ((! -d $filename) ||
        ($filename =~ /\.svn/) ||
        ($filename eq ".")
       )
    {
        return;
    }
    $filename =~ s!^\./!!;
    push @dirs, $filename;
}

find({ 'wanted' => \&wanted, 'no_chdir' => 1, }, ".");

print join("\n", @dirs), "\n";

foreach my $dir (@dirs)
{
    my (%sub_dirs, %modules, %preproc_modules);
    opendir DIR, $dir;
    while (my $file = readdir(DIR))
    {
        # Skip hidden files
        if (substr($file, 0, 1) eq ".")
        {
            next;
        }
        if (-d "$dir/$file")
        {
            $sub_dirs{$file} = 1;
        }
        if ($file =~ /\.pm\.pl$/)
        {
            $file =~ s/\.pm\.pl$//;
            $preproc_modules{$file} = 1;
        }
        if ($file =~ /\.pm$/)
        {
            $file =~ s/\.pm$//;
            $modules{$file} = 1;
        }
    }
    closedir(DIR);
    %modules = 
        (map { $_ => $modules{$_} } 
            (grep { !exists($preproc_modules{$_}) } 
                keys(%modules)
            )
        );
        
    open O, ">$dir/Makefile.am";
    print O "include \$(top_srcdir)/perl5/Shlomif/modules.am\n\n";

    if (scalar(keys(%sub_dirs)) > 0)
    {
        print O "SUBDIRS = " . join(" ", sort { $a cmp $b } keys(%sub_dirs)) . "\n\n";
    }
    if (scalar(keys(%modules)) + scalar(keys(%preproc_modules)) > 0)
    {
        print O "thesemodulesdir=\$(modulesdir)/Shlomif/$dir\n\n";
        
        print O "MODULES = " . join(" ", map { "$_.pm" } sort { $a cmp $b } keys(%modules)) . "\n";
        
        print O "PREPROCMODULES = " . join(" ", map { "$_.pm" } sort { $a cmp $b } keys(%preproc_modules)) . "\n";
        
        print O "PREPROCMODULES_SOURCES = " . join(" ", map { "$_.pm.pl" } sort { $a cmp $b } keys(%preproc_modules)) . "\n";

        print O "\n\n";
        
        print O "EXTRA_DIST = \$(MODULES) \$(PREPROCMODULES_SOURCES)\n\n";

        print O "thesemodules_DATA = \$(MODULES) \$(PREPROCMODULES)\n\n";

        foreach my $m (keys(%preproc_modules))
        {
            my $target = "$m.pm";
            my $src = "$target.pl";
                        
            print O "${target}: $src\n";
            print O "\tcat ${src} | sed 's!{QP_PKG_DATA_DIR}!\$(pkgdatadir)!g' > ${target}\n\n";
        }
    }
    close(O);
}
