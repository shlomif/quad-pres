# This .am file was generated using perl5/Shlomif/prepare_automake.pl
# Do not edit directly!!!

include $(top_srcdir)/perl5/Shlomif/modules.am


thesemodulesdir=$(modulesdir)/Shlomif/Quad/Pres

MODULES = CGI.pm CmdLine.pm Config.pm Config-new-fangled.pm Exception.pm FS.pm Getopt.pm Url.pm
PREPROCMODULES = Path.pm
PREPROCMODULES_SRCS = Path.pm.pl


EXTRA_DIST = $(MODULES) $(PREPROCMODULES_SRCS)

thesemodules_DATA = $(MODULES) $(PREPROCMODULES)

Path.pm: Path.pm.pl
	cat Path.pm.pl | sed 's!{QP_PKG_DATA_DIR}!$(pkgdatadir)!g' > Path.pm

