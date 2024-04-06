SET (s "${CMAKE_CURRENT_SOURCE_DIR}/quadp.pl")
SET (d "quadp")

ADD_CUSTOM_COMMAND(
    OUTPUT "${d}"
    COMMAND "${PERL_EXECUTABLE}"
    ARGS "-E" "use Path::Tiny qw/ path /; my $t = path(\"${s}\")->slurp_raw; $t =~ s#\\{QP_MODULES_DIR\\}#${PATH_PERL}#g; $t =~ s#/usr/bin/perl#${PERL_EXECUTABLE}#g; path(\"${d}\")->spew_raw($t); chmod(0755, \"${d}\");"
    DEPENDS "${s}"
    VERBATIM
)

# The custom command needs to be assigned to a target.
ADD_CUSTOM_TARGET(
    quadp_bin ALL
    DEPENDS "${d}"
)

SET (s "${CMAKE_CURRENT_SOURCE_DIR}/Shlomif/Quad/Pres/Path.pm.pl")
SET (d "${CMAKE_CURRENT_BINARY_DIR}/Shlomif/Quad/Pres/Path.pm")

ADD_CUSTOM_COMMAND(
    OUTPUT "${d}"
    COMMAND "${PERL_EXECUTABLE}"
    ARGS "-E" "use Path::Tiny qw/ path /; my $t = path(\"${s}\")->slurp_raw(); $t =~ s#\\{QP_MODULES_DIR\\}#${PATH_PERL}#g; $t =~ s#\\{QP_PKG_DATA_DIR\\}#${PKGDATADIR}#g; $t =~ s#/usr/bin/perl#${PERL_EXECUTABLE}#g; path(\"${d}\")->touchpath()->spew_raw($t);"
    DEPENDS "${s}"
    VERBATIM
)

ADD_CUSTOM_TARGET(
    Path_pm_pl ALL
    DEPENDS "${d}"
)

install( PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/quadp" DESTINATION bin )

#	cat quadp.pl | sed 's!{QP_MODULES_DIR}!$(modulesdir)!g' | sed '1 s!/usr/bin/perl!$(PATH_PERL)!' > quadp

SET( myfiles
        Shlomif/Quad/Pres/CGI.pm
        Shlomif/Quad/Pres/CmdLine.pm
        Shlomif/Quad/Pres/CmdLineMulti.pm
)

FOREACH (f ${myfiles})
    STRING (REGEX REPLACE "(^|/)[^/]+$" "" dirname "${f}")
    INSTALL (
        FILES
            "${f}"
        DESTINATION
            "${PATH_PERL}/${dirname}"
    )
ENDFOREACH (f ${myfiles})

INSTALL(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/Shlomif/Quad/Pres/Path.pm"
    DESTINATION
        "${PATH_PERL}/Shlomif/Quad/Pres"
)

