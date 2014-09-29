
include_directories(${KDE4_INCLUDES} ${KDE4_INCLUDE_DIR} ${QT_INCLUDES} )

add_subdirectory(themes)


########### install files ###############

install(FILES  $(WML_FILES) DESTINATION )



#original Makefile.am contents follow:

#include $(top_srcdir)/wml/wml.am
#
#SUBDIRS = themes
#
#wmlfilesdir = $(wmldir)
#
#WML_FILES = quadpres_main.wml wml_helpers.wml
#
#wmlfiles_DATA = $(WML_FILES)
#
#EXTRA_DIST = wml.am
#EXTRA_DIST += $(WML_FILES)
#
