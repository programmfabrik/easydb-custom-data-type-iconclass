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
	CustomDataTypeIconclass.config.yml

COFFEE_FILES = easydb-library/src/commons.coffee \
	src/webfrontend/CustomDataTypeIconclass.coffee \
  src/webfrontend/CustomDataTypeIconclassTreeview.coffee \
	src/webfrontend/IconclassUtil.coffee

CSS_FILE = src/webfrontend/css/main.css

all: build

include easydb-library/tools/base-plugins.make

build: code

code: $(subst .coffee,.coffee.js,${COFFEE_FILES}) $(L10N)
	mkdir -p build
	mkdir -p build/webfrontend
	cat $^ > build/webfrontend/custom-data-type-iconclass.js
	mkdir -p build/webfrontend/css
	cat $(CSS_FILE) >> build/webfrontend/custom-data-type-iconclass.css

clean: clean-base

wipe: wipe-base

.PHONY: clean wipe
