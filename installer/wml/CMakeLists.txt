
include_directories(${KDE4_INCLUDES} ${KDE4_INCLUDE_DIR} ${QT_INCLUDES} )

SET (wmldir "${DATADIR}/wml")

SET (WML_FILES
    "quadpres_main.wml"
    "themes/alon-altman-text/template.wml"
    "themes/shlomif-text/template.wml"
    "wml_helpers.wml"
)
########### install files ###############

FOREACH (f ${WML_FILES})
    STRING (REGEX REPLACE "/[^/]+$" "" dirname "${f}")
    INSTALL (
        FILES
            "${f}"
        DESTINATION
            "${wmldir}/${dirname}"
    )
ENDFOREACH (f ${myfiles})


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
