
include_directories(${KDE4_INCLUDES} ${KDE4_INCLUDE_DIR} ${QT_INCLUDES} )

add_subdirectory(Arad)
add_subdirectory(Gamla)
add_subdirectory(Quad)


########### install files ###############




#original Makefile.am contents follow:

#
#SUBDIRS = Arad Gamla Quad
#
#EXTRA_DIST = prepare_automake.pl modules.am
#
