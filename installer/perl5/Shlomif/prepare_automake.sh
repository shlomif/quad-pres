#!/bin/bash

find . -type d | grep -v -F '.svn' | grep -v '^\.$' | sed 's!^./!!' |
    (while read T ; do
        (
            echo "include \$(top_srcdir)/perl5/Shlomif/modules.am";
            echo ;
            num_dirs=0;
            for I in "$T"/* ; do
                if test -d "$I" ; then
                    let num_dirs++;
                fi;
            done
            if test $num_dirs -gt 0 ; then
                echo -n "SUBDIRS = ";
                (cd "$T" && (for I in * ; do test -d $I && echo -n "$I " ; done));
                echo ;
                echo ;
            fi
            
            num_modules="$(ls "$T"/*.pm{.pl,} | wc -l)"
            if test $num_modules -gt 0 ; then
                echo "thesemodulesdir=\$(modulesdir)/Shlomif/$T";
                echo ;
                
                (cd "$T" && 
                    echo -n "MODULES = ";
                    (ls *.pm | (while read I; do 
                        echo -n "$I " ; 
                     done)
                    echo;
                    echo -n "PREPROCMODULES = ";
                     ls *.pm.pl | (while read I; do
                        echo -n "${I%.pl} " ;
                     done)
                    echo;
                    echo -n "PREPROCMODULES_SOURCES = ";
                     ls *.pm.pl | (while read I; do
                        echo -n "${I} " ;
                     done)                     
                    )
                );
                echo ;
                echo ;
                echo "EXTRA_DIST = \$(MODULES) \$(PREPROCMODULES_SOURCES)";
                echo ;
                echo "thesemodules_DATA = \$(MODULES) \$(PREPROCMODULES)";
                echo ;
                (cd "$T" &&
                    (for I in *.pm.pl ; do
                        test -f "$I" && (
                            echo "${I%.pl}: $I"
                            echo -e -n "\\t"
                            echo "cat \$< | sed 's!{QP_PKG_DATA_DIR}!'\$(pkgdatadir)'!g' > \$@"
                            echo;
                        );
                    done
                    )
                )
            fi
       ) > "$T/Makefile.am"
   done)
            
