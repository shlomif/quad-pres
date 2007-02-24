include $(top_srcdir)/perl5/Shlomif/modules.am

PATH_PERL = @PATH_PERL@

qpscriptsdir = $(pkgdatadir)/scripts/

qpscripts_SCRIPTS = clear-tree.pl fix-gvim-html.pl html-server-to-hd.pl Render_all_contents.pl render-file.pl upload.pl

clear-tree.pl: clear-tree.pl.pl Makefile
	cat clear-tree.pl.pl | sed 's!{QP_MODULES_DIR}!$(modulesdir)!g' | sed '1 s!/usr/bin/perl!$(PATH_PERL)!' > clear-tree.pl
	chmod 755 clear-tree.pl

fix-gvim-html.pl: fix-gvim-html.pl.pl Makefile
	cat fix-gvim-html.pl.pl | sed 's!{QP_MODULES_DIR}!$(modulesdir)!g' | sed '1 s!/usr/bin/perl!$(PATH_PERL)!' > fix-gvim-html.pl
	chmod 755 fix-gvim-html.pl

html-server-to-hd.pl: html-server-to-hd.pl.pl Makefile
	cat html-server-to-hd.pl.pl | sed 's!{QP_MODULES_DIR}!$(modulesdir)!g' | sed '1 s!/usr/bin/perl!$(PATH_PERL)!' > html-server-to-hd.pl
	chmod 755 html-server-to-hd.pl

Render_all_contents.pl: Render_all_contents.pl.pl Makefile
	cat Render_all_contents.pl.pl | sed 's!{QP_MODULES_DIR}!$(modulesdir)!g' | sed '1 s!/usr/bin/perl!$(PATH_PERL)!' > Render_all_contents.pl
	chmod 755 Render_all_contents.pl

render-file.pl: render-file.pl.pl Makefile
	cat render-file.pl.pl | sed 's!{QP_MODULES_DIR}!$(modulesdir)!g' | sed '1 s!/usr/bin/perl!$(PATH_PERL)!' > render-file.pl
	chmod 755 render-file.pl

upload.pl: upload.pl.pl Makefile
	cat upload.pl.pl | sed 's!{QP_MODULES_DIR}!$(modulesdir)!g' | sed '1 s!/usr/bin/perl!$(PATH_PERL)!' > upload.pl
	chmod 755 upload.pl

EXTRA_DIST = clear-tree.pl.pl fix-gvim-html.pl.pl html-server-to-hd.pl.pl Render_all_contents.pl.pl render-file.pl.pl upload.pl.pl

EXTRA_DIST += gen_am.pl



