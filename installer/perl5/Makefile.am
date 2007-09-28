include $(top_srcdir)/perl5/Shlomif/modules.am

PATH_PERL = @PATH_PERL@

SUBDIRS = Shlomif

bin_SCRIPTS = quadp

man_MANS = quadp.1

quadp : quadp.pl Makefile
	cat quadp.pl | sed 's!{QP_MODULES_DIR}!$(modulesdir)!g' | sed '1 s!/usr/bin/perl!$(PATH_PERL)!' > quadp

quadp.1: quadp
	pod2man --section=1 --center="Quad-Pres" quadp > quadp.1

EXTRA_DIST = quadp.pl

