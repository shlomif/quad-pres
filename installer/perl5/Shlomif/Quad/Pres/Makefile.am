include $(top_srcdir)/perl5/Shlomif/modules.am

thesemodulesdir=$(modulesdir)/Shlomif/Quad/Pres

MODULES = CGI.pm CmdLine.pm Config.pm Exception.pm FS.pm Url.pm
PREPROCMODULES = Path.pm
PREPROCMODULES_SOURCES = Path.pm.pl


EXTRA_DIST = $(MODULES) $(PREPROCMODULES_SOURCES)

thesemodules_DATA = $(MODULES) $(PREPROCMODULES)

Path.pm: Path.pm.pl
	cat Path.pm.pl | sed 's!{QP_PKG_DATA_DIR}!$(pkgdatadir)!g' > Path.pm

