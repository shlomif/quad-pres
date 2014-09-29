
include_directories(${KDE4_INCLUDES} ${KDE4_INCLUDE_DIR} ${QT_INCLUDES} )

########### install files ###############

install(FILES  quadp DESTINATION bin )

SET (s "${CMAKE_CURRENT_SOURCE_DIR}/quadp.pl")
SET (d "quadp")

SET (PATH_PERL "${libdir}/perl5")
ADD_CUSTOM_COMMAND(
    OUTPUT "${d}"
    COMMAND ${PERL_EXECUTABLE}
    ARGS "-E" "use IO::All; my $t = io->file(\"${s}\")->slurp; $t =~ s#\\{QP_MODULES_DIR\\}#${PATH_PERL}#g; $t =~ s#/usr/bin/perl#${PATH_PERL}#ge; io->file(\"${d}\")->print($t)"
    DEPENDS "${s}"
    VERBATIM
)

#	cat quadp.pl | sed 's!{QP_MODULES_DIR}!$(modulesdir)!g' | sed '1 s!/usr/bin/perl!$(PATH_PERL)!' > quadp

INSTALL(
    FILES
        Shlomif/Arad/Object.pm
        Shlomif/Gamla/Object.pm
        Shlomif/Quad/Pres.pm
        Shlomif/Quad/Pres/CGI.pm
        Shlomif/Quad/Pres/CmdLine.pm
        Shlomif/Quad/Pres/Config.pm
        Shlomif/Quad/Pres/Exception.pm
        Shlomif/Quad/Pres/FS.pm
        Shlomif/Quad/Pres/Getopt.pm
        Shlomif/Quad/Pres/Path.pm
        Shlomif/Quad/Pres/Url.pm
        Shlomif/Quad/Pres/WriteContents.pm
    DESTINATION
        "${PATH_PERL}"
)


#original Makefile.am contents follow:

#include $(top_srcdir)/perl5/Shlomif/modules.am
#
#PATH_PERL = @PATH_PERL@
#
#SUBDIRS = Shlomif
#
#bin_SCRIPTS = quadp
#
#man_MANS = quadp.1
#
#quadp : quadp.pl Makefile
#	cat quadp.pl | sed 's!{QP_MODULES_DIR}!$(modulesdir)!g' | sed '1 s!/usr/bin/perl!$(PATH_PERL)!' > quadp
#
#quadp.1: quadp
#	pod2man --section=1 --center="Quad-Pres" quadp > quadp.1
#
#EXTRA_DIST = quadp.pl
#
