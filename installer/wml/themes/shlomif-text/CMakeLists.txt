
include_directories(${KDE4_INCLUDES} ${KDE4_INCLUDE_DIR} ${QT_INCLUDES} )


########### install files ###############

install(FILES  $(WML_FILES) DESTINATION )



#original Makefile.am contents follow:

#include $(top_srcdir)/wml/wml.am
#
#themewmlfilesdir=$(wmlthemesdir)/shlomif-text
#
#WML_FILES = template.wml
#themewmlfiles_DATA = $(WML_FILES)
#
#EXTRA_DIST = $(WML_FILES)
#
