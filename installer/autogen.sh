#!/bin/sh

(cd perl5/Shlomif && perl prepare_automake.pl)
aclocal
automake
automake --add-missing
autoconf
