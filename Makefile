PLUGIN_NAME = custom-data-type-iconclass

L10N_FILES = easydb-library/src/commons.l10n.csv \
    l10n/$(PLUGIN_NAME).csv
L10N2JSON = python easydb-library/tools/l10n2json.py

INSTALL_FILES = \
	$(WEB)/l10n/cultures.json \
	$(WEB)/l10n/de-DE.json \
	$(WEB)/l10n/en-US.json \
	$(WEB)/l10n/es-ES.json \
	$(WEB)/l10n/it-IT.json \
	$(JS) \
	$(CSS) \
	CustomDataTypeIconclass.config.yml \
	build/updater/iconclass-update.js

COFFEE_FILES = easydb-library/src/commons.coffee \
	src/webfrontend/CustomDataTypeIconclass.coffee \
  src/webfrontend/CustomDataTypeIconclassTreeview.coffee \
	src/webfrontend/IconclassUtil.coffee

CSS_FILE = src/webfrontend/css/main.css

UPDATE_SCRIPT_COFFEE_FILES = \
	src/webfrontend/IconclassUtil.coffee \
	src/updater/iconclassUpdate.coffee

all: build

include easydb-library/tools/base-plugins.make

build: code buildinfojson buildupdater

code: $(subst .coffee,.coffee.js,${COFFEE_FILES}) $(L10N)
	mkdir -p build
	mkdir -p build/webfrontend
	cat $^ > build/webfrontend/custom-data-type-iconclass.js
	mkdir -p build/webfrontend/css
	cat $(CSS_FILE) >> build/webfrontend/custom-data-type-iconclass.css

buildupdater: $(subst .coffee,.coffee.js,${UPDATE_SCRIPT_COFFEE_FILES})
	mkdir -p build/updater
	cat $^ > build/updater/iconclass-update.js

clean: clean-base

wipe: wipe-base

.PHONY: clean wipe
