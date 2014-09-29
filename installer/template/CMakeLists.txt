
include_directories(${KDE4_INCLUDES} ${KDE4_INCLUDE_DIR} ${QT_INCLUDES} )

SET (MYFILES style.css template.html.wml)
########### install files ###############

install(FILES  ${MYFILES} DESTINATION "${DATADIR}/template")

#original Makefile.am contents follow:

#
#templatefilesdir = $(pkgdatadir)/template
#
#MYFILES = style.css template.html.wml
#templatefiles_DATA = $(MYFILES)
#
#EXTRA_DIST = $(MYFILES)
#
