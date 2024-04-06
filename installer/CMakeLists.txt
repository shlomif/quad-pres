# see - http://www.cmake.org/Wiki/CMake_FAQ#Is_there_an_option_to_produce_more_.27verbose.27_compiling.3F
# SET(CMAKE_VERBOSE_MAKEFILE ON)

cmake_minimum_required(VERSION 3.6)

project("quad-pres")

INCLUDE ("${CMAKE_SOURCE_DIR}/cmake/shlomif_common_bootstrap.cmake")
SHLOMIF_COMMON_SETUP("${private_mod_path}")

SET (PKGDATADIR "${DATADIR}/quad-pres")
SET (PATH_PERL "${PKGDATADIR}/perl5")

add_subdirectory(perl5)
add_subdirectory(wml)
add_subdirectory(template)

# This is the equivalent to perform a "make dist"/"make distdir" etc.
SET(CPACK_PACKAGE_NAME "quad-pres")
SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Quad-Pres - a tool for HTML presentations")
SET(CPACK_PACKAGE_VENDOR "Shlomi Fish")
SET(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
SET(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/COPYING")

# Process and extract the version number.
FILE( READ "ver.txt" VERSION)

CHOMP (VERSION)

STRING (REGEX MATCHALL "([0-9]+)" VERSION_DIGITS "${VERSION}")

LIST(GET VERSION_DIGITS 0 CPACK_PACKAGE_VERSION_MAJOR)
LIST(GET VERSION_DIGITS 1 CPACK_PACKAGE_VERSION_MINOR)
LIST(GET VERSION_DIGITS 2 CPACK_PACKAGE_VERSION_PATCH)

SET(CPACK_PACKAGE_INSTALL_DIRECTORY "${CPACK_PACKAGE_DESCRIPTION_SUMMARY} ${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

SET(CPACK_SOURCE_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

SET (base_with_ver "${CPACK_PACKAGE_NAME}-[0-9]+\\\\.[0-9]+\\\\.[0-9]+")

SET(CPACK_SOURCE_IGNORE_FILES
    "/.deps/"
    "~$"
    "/tags$"
    "ids-whitelist\\\\.txt"
)

IF(WIN32 AND NOT UNIX)
    # There is a bug in NSI that does not handle full unix paths properly. Make
    # sure there is at least one set of four (4) backlasshes.
    # SET(CPACK_PACKAGE_ICON "${CMAKE_SOURCE_DIR}\\\\dondorf-king.bmp")
    SET(CPACK_NSIS_INSTALLED_ICON_NAME "bin\\\\wml.exe")
    SET(CPACK_NSIS_HELP_LINK "http:\\\\\\\\www.shlomifish.org\\quad-pres\\")
    SET(CPACK_NSIS_URL_INFO_ABOUT "${CPACK_NSIS_HELP_LINK}")
    SET(CPACK_NSIS_DISPLAY_NAME "Quad-Pres")
    SET(CPACK_NSIS_CONTACT "shlomif@cpan.org")
    SET(CPACK_NSIS_MODIFY_PATH ON)
    # Setting for NSIS :
    SET(CPACK_NSIS_MUI_ICON "${CMAKE_CURRENT_SOURCE_DIR}\\\\wml.ico")
    SET(CPACK_NSIS_MUI_UNIICON ${CPACK_NSIS_MUI_ICON})
    SET(CPACK_PACKAGE_ICON ${CPACK_NSIS_MUI_ICON})
    SET(CPACK_NSIS_MODIFY_PATH "ON")
ELSE ()
    # SET(CPACK_STRIP_FILES "")
    # SET(CPACK_SOURCE_STRIP_FILES "")
ENDIF ()

SET(CPACK_PACKAGE_EXECUTABLES
    "quadp" "Quad-Pres Frontend"
)

INCLUDE (CPack)

CONFIGURE_FILE(
    ${CMAKE_CURRENT_SOURCE_DIR}/${CPACK_PACKAGE_NAME}.spec.in
    ${CMAKE_CURRENT_SOURCE_DIR}/${CPACK_PACKAGE_NAME}.spec
)

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
