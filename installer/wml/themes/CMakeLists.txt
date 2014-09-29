
include_directories(${KDE4_INCLUDES} ${KDE4_INCLUDE_DIR} ${QT_INCLUDES} )

add_subdirectory(alon-altman-text)
add_subdirectory(shlomif-text)


########### install files ###############




#original Makefile.am contents follow:

#include $(top_srcdir)/wml/wml.am
#
#SUBDIRS = alon-altman-text shlomif-text
#
