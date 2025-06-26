include shared.mk

# The SQL files for the install script and upgrade scripts
DATA := $(wildcard $(data_directory_name)/*.sql)
# The file that contains the license that the software is released under
DOCS := $(license_file_name)
# TODO: Write a perl script to run all of the tests after the extension is installed.
TAP_TESTS :=

PG_CONFIG := pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)