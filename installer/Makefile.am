SUBDIRS = perl5 wml template

EXTRA_DIST += ver.txt

EXTRA_DIST += quad-pres.spec quad-pres.spec.in

check: prepare_check purecheck

prepare_check:
	@rm -fr tests/installation
	@mkdir tests/installation
	@make clean
	@make install prefix=`pwd`/tests/installation

purecheck:
	@PATH=`pwd`/tests/installation:$$PATH ; \
	export PERL5LIB=`pwd`/tests/installation/share/quad-pres/perl5/ ; \
	make -C tests

