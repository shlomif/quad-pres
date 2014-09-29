
include_directories(${KDE4_INCLUDES} ${KDE4_INCLUDE_DIR} ${QT_INCLUDES} )

add_subdirectory(Pres)


########### install files ###############

install(FILES  $(MODULES) $(PREPROCMODULES) DESTINATION )



#original Makefile.am contents follow:

## This .am file was generated using perl5/Shlomif/prepare_automake.pl
## Do not edit directly!!!
#
#include $(top_srcdir)/perl5/Shlomif/modules.am
#
#
#SUBDIRS = Pres
#
#thesemodulesdir=$(modulesdir)/Shlomif/Quad
#
#MODULES = Pres.pm
#PREPROCMODULES =
#PREPROCMODULES_SRCS =
#
#
#EXTRA_DIST = $(MODULES) $(PREPROCMODULES_SRCS)
#
#thesemodules_DATA = $(MODULES) $(PREPROCMODULES)
#
