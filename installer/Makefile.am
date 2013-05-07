SUBDIRS = perl5 wml template

EXTRA_DIST = ver.txt

EXTRA_DIST += quad-pres.spec quad-pres.spec.in
EXTRA_DIST += autogen.sh prepare_package.sh

check: prepare_check purecheck

prepare_check:
	@rm -fr tests/installation
	@mkdir tests/installation
	@make distdir
	@myprefix=`pwd`/tests/installation ; \
		cd quad-pres-`cat ver.txt` ;  \
		./configure --prefix="$$myprefix" ; \
		make install

purecheck:
	@PATH=`pwd`/tests/installation/bin:$$PATH ; \
	export PERL5LIB="`pwd`/tests/installation/share/quad-pres/perl5/:$PERL5LIB" ; \
	export QUAD_PRES_NO_HOME_LIB=1 ; \
	make -C tests check

dist-hook:
	mkdir $(distdir)/tests
	cat $(srcdir)/tests/MANIFEST | (while read T ; do dest=$(distdir)/tests/"$$T" ; mkdir -p `dirname "$$dest"` ; cp -p $(srcdir)/tests/"$$T" "$$dest" ; done)

