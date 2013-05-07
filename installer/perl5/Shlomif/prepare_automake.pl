#!/usr/bin/perl

use strict;
use warnings;

use autodie;

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

foreach my $dir_path (@dirs)
{
    my (%sub_dirs, %modules, %preproc_modules);

    my $dh;
    opendir $dh, $dir_path;
    my @entries = File::Spec->no_upwards(readdir ($dh));
    closedir($dh);

    foreach my $file (@entries)
    {
        # Skip hidden files
        if (-d "$dir_path/$file")
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

    open my $o, ">$dir_path/Makefile.am";
    print {$o} <<'EOF';
# This .am file was generated using perl5/Shlomif/prepare_automake.pl
# Do not edit directly!!!

include $(top_srcdir)/perl5/Shlomif/modules.am


EOF

    if (scalar(keys(%sub_dirs)) > 0)
    {
        print {$o} "SUBDIRS = " . join(" ", sort { $a cmp $b } keys(%sub_dirs)) . "\n\n";
    }
    if (scalar(keys(%modules)) + scalar(keys(%preproc_modules)) > 0)
    {
        print {$o} "thesemodulesdir=\$(modulesdir)/Shlomif/$dir_path\n\n";

        print {$o} "MODULES = " . join(" ", map { "$_.pm" } sort { $a cmp $b } keys(%modules)) . "\n";

        print {$o} "PREPROCMODULES = " . join(" ", map { "$_.pm" } sort { $a cmp $b } keys(%preproc_modules)) . "\n";

        print {$o} "PREPROCMODULES_SRCS = " . join(" ", map { "$_.pm.pl" } sort { $a cmp $b } keys(%preproc_modules)) . "\n";

        print {$o} "\n\n";

        print {$o} "EXTRA_DIST = \$(MODULES) \$(PREPROCMODULES_SRCS)\n\n";

        print {$o} "thesemodules_DATA = \$(MODULES) \$(PREPROCMODULES)\n\n";

        foreach my $m (keys(%preproc_modules))
        {
            my $target = "$m.pm";
            my $src = "$target.pl";

            print {$o} "${target}: $src\n";
            print {$o} "\tcat ${src} | sed 's!{QP_PKG_DATA_DIR}!\$(pkgdatadir)!g' > ${target}\n\n";
        }
    }

    close($o);
}
