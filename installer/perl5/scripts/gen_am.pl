#!/usr/bin/perl -w

use strict;

my @perl_scripts=
(
    qw(clear-tree.pl fix-gvim-html.pl html-server-to-hd.pl),
    qw(Render_all_contents.pl render-file.pl upload.pl)
);

open O, ">Makefile.am";
print O <<'EOF' ;
include $(top_srcdir)/perl5/Shlomif/modules.am

PATH_PERL = @PATH_PERL@

qpscriptsdir = $(pkgdatadir)/scripts/

EOF

print O "qpscripts_SCRIPTS = " . join(" ", @perl_scripts) . "\n\n";

foreach my $script (@perl_scripts)
{
    print O "${script}: $script.pl Makefile\n";
    print O "\tcat ${script}.pl | " .
        "sed 's!{QP_MODULES_DIR}!\$(modulesdir)!g' | " .
        "sed '1 s!/usr/bin/perl!\$(PATH_PERL)!' " .
        "> $script\n";
    print O "\tchmod 755 ${script}\n";
    print O "\n";
}

print O "EXTRA_DIST += " . join(" ", (map { "$_.pl" } @perl_scripts)) . "\n\n";

print O "EXTRA_DIST += gen_am.pl\n\n";

print O "\n\n";

close(O);

