> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# easydb-custom-data-type-iconclass

This is a plugin for [easyDB 5](http://5.easydb.de/) with Custom Data Type `CustomDataTypeIconclass` for references to entities of the [Iconclass-Vokabulary (http://iconclass.org/)](http://iconclass.org/).

The Plugins uses the mechanisms from <http://iconclass.org/help/lod> for the communication with Iconclass.

## configuration

As defined in `CustomDataTypeIconclass.config.yml` this datatype can be configured:

### Schema options
-
### Mask options
-

## saved data
* conceptName
    * Preferred label of the linked record
* conceptURI
    * URI to linked record
* conceptFulltext
    * fulltext-string which contains: PrefLabels, AltLabels, HiddenLabels, Notations
* conceptAncestors
    * URI's of all given ancestors
* _fulltext
    * easydb-fulltext
* _standard
    * easydb-standard

## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/easydb-custom-data-type-iconclass>. Please use [the issue tracker](https://github.com/programmfabrik/easydb-custom-data-type-iconclass/issues) for bug reports and feature requests!
