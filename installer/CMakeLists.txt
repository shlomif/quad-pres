# see - http://www.cmake.org/Wiki/CMake_FAQ#Is_there_an_option_to_produce_more_.27verbose.27_compiling.3F
# SET(CMAKE_VERBOSE_MAKEFILE ON)

SET (private_mod_path "${CMAKE_SOURCE_DIR}/cmake")
LIST (APPEND CMAKE_MODULE_PATH "${private_mod_path}")
INCLUDE(Shlomif_Common)

SHLOMIF_COMMON_SETUP("${private_mod_path}")
cmake_minimum_required(VERSION 2.8)

include_directories(${KDE4_INCLUDES} ${KDE4_INCLUDE_DIR} ${QT_INCLUDES} )

SET (libdir "${CMAKE_INSTALL_PREFIX}/lib")
SET (PATH_PERL "${libdir}/perl5")

add_subdirectory(perl5)
add_subdirectory(wml)
add_subdirectory(template)


########### install files ###############

ENABLE_TESTING()

ADD_TEST(
    NAME perl_run_tests
    COMMAND "perl" "${CMAKE_CURRENT_SOURCE_DIR}/run_test.pl"
)

ADD_CUSTOM_TARGET(
    "check"
    "perl" "${CMAKE_CURRENT_SOURCE_DIR}/run_test.pl"
)

#original Makefile.am contents follow:

#SUBDIRS = perl5 wml template
#
#EXTRA_DIST = ver.txt
#
#EXTRA_DIST += quad-pres.spec quad-pres.spec.in
#EXTRA_DIST += autogen.sh prepare_package.sh
#
#check: prepare_check purecheck
#
#prepare_check:
#	@rm -fr tests/installation
#	@mkdir tests/installation
#	@make distdir
#	@myprefix=`pwd`/tests/installation ; \
#		cd quad-pres-`cat ver.txt` ;  \
#		./configure --prefix="$$myprefix" ; \
#		make install
#
#purecheck:
#	@PATH=`pwd`/tests/installation/bin:$$PATH ; \
#	export PERL5LIB="`pwd`/tests/installation/share/quad-pres/perl5/:$$PERL5LIB" ; \
#	export QUAD_PRES_NO_HOME_LIB=1 ; \
#	make -C tests check
#
#dist-hook:
#	mkdir $(distdir)/tests
#	cat $(srcdir)/tests/MANIFEST | (while read T ; do dest=$(distdir)/tests/"$$T" ; mkdir -p `dirname "$$dest"` ; cp -p $(srcdir)/tests/"$$T" "$$dest" ; done)
#
