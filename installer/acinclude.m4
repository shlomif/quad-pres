AC_DEFUN(AC_CHECK_PERL_INTERPRETER,[dnl
AC_MSG_CHECKING([for Perl language])
AC_ARG_WITH(perl,dnl
[  --with-perl=PATH        force the usage of a specific Perl 5 interpreter],[
dnl [[
perlprog=$with_perl
perlvers=`$perlprog -e 'printf "%.3f",$]'`
dnl ]
],[
perlvers=
for dir in `echo $PATH | sed -e 's/:/ /g'` $tmpdir; do
    for perl in perl perl5 miniperl; do
         if test -f "$dir/$perl"; then
             if test -x "$dir/$perl"; then
                 perlprog="$dir/$perl"
                 if $perlprog -e 'require 5.003'; then
dnl [[
                     perlvers=`$perlprog -e 'printf "%.3f",$]'`
dnl ]
                     break 2
                 fi
             fi
         fi
    done
done
])dnl
PATH_PERL=$perlprog
AC_MSG_RESULT([$perlprog v$perlvers])
if $perlprog -e 'require 5.003'; then
    :
else
    echo ""
    echo "Latest Perl found on your system is $perlvers,"
    echo "but at least Perl version 5.003 is required."
    echo "In case the newer one is not in PATH, just use"
    echo "the option --with-perl=/path/to/bin/perl to"
    echo "provide the correct executable."
    echo ""
    AC_ERROR([Perl version too old]) 
fi
AC_SUBST(PATH_PERL)
AC_SUBST(perlprog)
AC_SUBST(perlvers)
])dnl

