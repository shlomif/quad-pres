SET (wmldir "${PKGDATADIR}/wml")

SET (WML_FILES
    "quadpres_main.wml"
    "themes/alon-altman-text/template.wml"
    "themes/shlomif-text/template.wml"
    "wml_helpers.wml"
)
########### install files ###############

FOREACH (f ${WML_FILES})
    STRING (REGEX REPLACE "(^|/)[^/]+$" "" dirname "${f}")
    INSTALL (
        FILES
            "${f}"
        DESTINATION
            "${wmldir}/${dirname}"
    )
ENDFOREACH ()
