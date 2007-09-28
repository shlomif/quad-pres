dnl Process this file with autoconf to produce a configure script.
dnl AC_INIT(perl5/Shlomif/Quad/Pres.pm)
AC_INIT(perl5/quadp.pl)

AC_PROG_MAKE_SET
AC_PROG_RANLIB

AM_INIT_AUTOMAKE([quad-pres], [`cat ./ver.txt`])

AM_PROG_LIBTOOL

AC_CHECK_PERL_INTERPRETER
if test -f $PATH_PERL; then
    :
else
    AC_ERROR([required program ``perl'' not found])
fi

AC_OUTPUT([Makefile perl5/Makefile
           perl5/Shlomif/Makefile perl5/Shlomif/Arad/Makefile 
           perl5/Shlomif/Quad/Makefile perl5/Shlomif/Quad/Pres/Makefile 
           perl5/Shlomif/Gamla/Makefile 
           wml/Makefile wml/themes/Makefile wml/themes/shlomif-text/Makefile 
           wml/themes/alon-altman-text/Makefile
           template/Makefile 
           quad-pres.spec
           ])

