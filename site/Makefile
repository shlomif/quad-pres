TARGET = dest

PAGES = download index made_with

SOURCES = $(addprefix src/,$(addsuffix .html.wml,$(PAGES)))

DESTS = $(patsubst src/%.html.wml,$(TARGET)/%.html,$(SOURCES))

RAW_FILES = style.css images/pa051.jpg quad-pres-0.8.0.tar.gz CatB-Quad-Pres-Lecture.tar.gz W2L-Basic-Use-Lecture.tar.gz quad-pres-0.14.0.tar.bz2 quad-pres-0.16.0.tar.xz quad-pres-0.18.0.tar.xz quad-pres-0.20.0.tar.xz quad-pres-0.22.0.tar.xz quad-pres-0.24.0.tar.xz quad-pres-0.24.1.tar.xz quad-pres-0.26.0.tar.xz quad-pres-0.28.0.tar.xz quad-pres-0.28.1.tar.xz quad-pres-0.30.0.tar.xz
RAW_FILES_SOURCES = $(addprefix src/,$(RAW_FILES))
RAW_FILES_DEST = $(addprefix $(TARGET)/,$(RAW_FILES))

SUBDIRS = images

SUBDIRS_DEST = $(addprefix $(TARGET)/,$(SUBDIRS))

WML_FLAGS += --passoption=2,-X --passoption=7,"-S imgsize" -DROOT~.

RSYNC = rsync --progress --verbose --rsh=ssh

all: dest $(SUBDIRS_DEST) $(DESTS) $(RAW_FILES_DEST) dest/download.html

$(DESTS) : $(TARGET)/% : src/%.wml template.wml $(DEVEL_VERSION_FILE)
	(cd src && wml $(WML_FLAGS) -DFILENAME=$(patsubst src/%.wml,%,$<) -DDEVEL_VERSION=$(DEVEL_VERSION) $(patsubst src/%,%,$<)) > $@

$(RAW_FILES_DEST) : $(TARGET)/% : src/%
	cp -f $< $@

dest $(SUBDIRS_DEST) : % :
	mkdir -p $@

upload: all
	(cd dest && $(RSYNC) -a * $${__HOMEPAGE_REMOTE_PATH}/quad-pres)
