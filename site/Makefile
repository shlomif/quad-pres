
TARGET = dest

PAGES = index

SOURCES = $(addprefix src/,$(addsuffix .html.wml,$(PAGES)))

DESTS = $(patsubst src/%.html.wml,$(TARGET)/%.html,$(SOURCES))

RAW_FILES = style.css images/pa051.jpg quad-pres-0.8.0.tar.gz CatB-Quad-Pres-Lecture.tar.gz W2L-Basic-Use-Lecture.tar.gz
RAW_FILES_SOURCES = $(addprefix src/,$(RAW_FILES))
RAW_FILES_DEST = $(addprefix $(TARGET)/,$(RAW_FILES))

PODS = $(addprefix docs/,roadmap spec whitepaper version-0.2-spec)
PODS_DESTS_HTMLS = $(patsubst %,$(TARGET)/%.html,$(PODS))
PODS_DESTS_PODS = $(patsubst %,$(TARGET)/%.pod,$(PODS))

FROM_REPOS_DIR = from-repos
DEVEL_PACKAGE_DIR = $(FROM_REPOS_DIR)/devel

DEVEL_VERSION_FILE = $(DEVEL_PACKAGE_DIR)/ver.txt
DEVEL_VERSION = $(shell cat $(DEVEL_VERSION_FILE))
DEVEL_PACKAGE_FILENAME=quad-pres-$(DEVEL_VERSION).tar.gz
DEVEL_PACKAGE = dest/$(DEVEL_PACKAGE_FILENAME)

PACKAGES_DIR = $(TARGET)/download/arcs
# PACKAGES = $(shell cd temp && cd lk-module-compiler-final && ls)
PACKAGES = 
PACKAGES_DESTS = $(addprefix $(PACKAGES_DIR)/,$(PACKAGES))

SUBDIRS = images

SUBDIRS_DEST = $(addprefix $(TARGET)/,$(SUBDIRS))

WML_FLAGS += --passoption=2,-X --passoption=7,"-S imgsize" -DROOT~.

RSYNC = rsync --progress --verbose --rsh=ssh 

# all: dest $(SUBDIRS_DEST) $(DESTS) $(RAW_FILES_DEST) $(PODS_DESTS) $(PODS_DESTS_HTMLS) $(PACKAGES_DESTS)
all: dest $(SUBDIRS_DEST) $(DESTS) $(RAW_FILES_DEST) $(DEVEL_PACKAGE) dest/download.html


dest:
	if [ ! -e $@ ] ; then mkdir $@ ; fi
	
$(DESTS) :: $(TARGET)/% : src/%.wml template.wml
	(cd src && wml $(WML_FLAGS) -DFILENAME=$(patsubst src/%.wml,%,$<) $(patsubst src/%,%,$<)) > $@

dest/download.html : src/download.html.wml template.wml $(DEVEL_VERSION_FILE)
	(cd src && wml $(WML_FLAGS) -DFILENAME=$(patsubst src/%.wml,%,$<) -DDEVEL_VERSION=$(DEVEL_VERSION) $(patsubst src/%,%,$<)) > $@

$(RAW_FILES_DEST) :: $(TARGET)/% : src/%
	cp -f $< $@

$(SUBDIRS_DEST) :: % : unchanged
	if [ ! -e $@ ] ; then mkdir $@ ; fi

$(PODS_DESTS) :: $(TARGET)/% : src/%
	cp -f $< $@

$(PODS_DESTS_HTMLS) :: $(TARGET)/%.html : src/%.pod
	pod2html $< > $@

$(PACKAGES_DESTS) :: $(PACKAGES_DIR)/% : ./temp/lk-module-compiler-final/%
	cp -f $< $@

$(DEVEL_PACKAGE) : $(DEVEL_PACKAGE_DIR)/$(DEVEL_PACKAGE_FILENAME) $(DEVEL_VERSION_FILE)
	cp -f $< $@

upload: all
	(cd dest && $(RSYNC) -r * shlomif@vipe.technion.ac.il:public_html/quadpres/)

ARC_NAME = CLAN-$(shell date +%Y-%m-%d).tar.gz

arc: $(ARC_NAME)

del_arc:
	rm -f $(ARC_NAME)

rearc: del_arc arc

$(ARC_NAME):
	(cd temp && ./make-archive.sh)

upload_arc: arc
	$(RSYNC) $(ARC_NAME) shlomif@shell.berlios.de:

	
	
