SUBDIRS = perl5 wml template

EXTRA_DIST += ver.txt

EXTRA_DIST += quad-pres.spec quad-pres.spec.in

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
	export PERL5LIB=`pwd`/tests/installation/share/quad-pres/perl5/ ; \
	make -C tests

