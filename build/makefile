# The directories where built files will be stored
output_directory := ../dist
output_archive_directory := ../zip
# This makefile contains variables that are needed both by this makefile and the install makefile
shared_makefile := shared.mk
output_shared_makefile := $(output_directory)/$(shared_makefile)
include $(shared_makefile)
# The directory that will contain the SQL files for installing or upgrading the extension
output_data_directory := $(output_directory)/$(data_directory_name)
# The makefile that will be used to install the extension
install_makefile := ../install/install.mk
output_install_makefile := $(output_directory)/makefile
# The control file used by PGXS to install the extension
control_file := ../install/pgtap_fixture.control
output_control_file := $(output_directory)/$(notdir $(control_file))
# The directory where sqitch should be executed from
sqitch_directory := ../src/sqitch
# The name of the sqitch plan file that will be used to generate the update scripts
sqitch_upgrade_plan_name := upgrade.plan
# The name of the sqitch plan file that will be used to generate the install script
sqitch_install_plan_name := install.plan
# The path to the plan file that will be used to generate the update scripts
sqitch_upgrade_plan_file := $(sqitch_directory)/$(sqitch_upgrade_plan_name)
# The path to the plan file that will be used to generate the install script
sqitch_install_plan_file := $(sqitch_directory)/$(sqitch_install_plan_name)
# Get the tags, upgrade plan, install plan, and current version from sqitch.
# These are all retrieved once, so no more calls need to be made to sqitch after this.
sqitch_info != ./build_utils.sh get_sqitch_info \
	$(sqitch_directory) $(sqitch_upgrade_plan_name) $(sqitch_install_plan_name)
sqitch_tags := $(word 1, $(sqitch_info))
sqitch_upgrade_plan := $(word 2, $(sqitch_info))
sqitch_install_plan := $(word 3, $(sqitch_info))
current_version := $(word 4, $(sqitch_info))
# Get the names of the upgrade and downgrade scripts that will be generated
upgrade_sql_files := \
	$(shell ./build_utils.sh get_targets upgrade \
		$(EXTENSION) \
		$(output_directory)/$(data_directory_name) \
		$(sqitch_tags) \
	) \
	$(shell ./build_utils.sh get_targets downgrade \
		$(EXTENSION) \
		$(output_directory)/$(data_directory_name) \
		$(sqitch_tags) \
	)
# Get the name of the install script that will be generated
install_sql_file != ./build_utils.sh get_targets install \
	$(EXTENSION) \
	$(output_directory)/$(data_directory_name) \
	$(sqitch_tags)
# A zipped archive that can be distributed
output_archive_type_tar_option := z
output_archive_suffix := .tar.gz
output_archive := $(output_archive_directory)/$(EXTENSION)-$(current_version)$(output_archive_suffix)



.PHONY : all

all : $(upgrade_sql_files) $(install_sql_file) $(output_install_makefile) $(output_shared_makefile) \
	$(output_control_file) $(output_archive)

# Create the output directories. Use these targets as order-only prerequisites of the targets that belong
# in the output directories.
$(output_data_directory) :
	mkdir -p $(output_data_directory)
$(output_directory) :
	mkdir -p $(output_directory)
$(output_archive_directory) :
	mkdir -p $(output_archive_directory)

# Create a zipped archive of the output content
$(output_archive) : $(upgrade_sql_files) $(install_sql_file) $(output_install_makefile) \
	$(output_shared_makefile) $(output_control_file) \
	| $(output_archive_directory)
	tar $(output_archive_type_tar_option)cvf $(output_archive) --transform "s,^dist,$(EXTENSION)-$(current_version)," $(output_directory)

# Copy the makefiles that install the extension to the output
$(output_install_makefile) : $(install_makefile) | $(output_directory)
	cp $< $@
$(output_shared_makefile) : $(shared_makefile) | $(output_directory)
	cp $< $@

# Copy the control file to the output and set its default version to the current version
$(output_control_file) : $(control_file) $(install_sql_file)
	cp $< $@
	printf "\ndefault_version = $(current_version)" >> $@

# Generate the install script by combining all of the SQL scripts in the install plan. Also execute this target
# if the install plan file changes, as the changes may have been reordered.
$(install_sql_file) : $(shell ./build_utils.sh get_all_prerequisites "$(sqitch_install_plan)") \
	$(sqitch_install_plan_file) \
	| $(output_data_directory)
	touch $@
	./build_utils.sh append_sql_files exclude_transaction $@ $(filter %.sql,$^)

.SECONDEXPANSION:

# For each upgrade or downgrade script, get the SQL scripts from the upgrade plan that correspond with the
# start and end version names and combine them. Also execute this target if the upgrade plan file changes,
# as the changes may have been reordered.
$(upgrade_sql_files) : $$(shell ./build_utils.sh get_upgrade_prerequisites $$(EXTENSION) $$@ "$$(sqitch_upgrade_plan)") \
	$(sqitch_upgrade_plan_file) \
	| $(output_data_directory)
	touch $@
	./build_utils.sh append_sql_files exclude_transaction $@ $(filter %.sql,$^)
