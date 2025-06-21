#!/usr/bin/sh

# Get the tags, upgrade plan, install plan, and current version from sqitch. All sqitch commands should go
# in this function and not in other functions. The current version is the last sqitch tag, or "x.x.x" if
# the last change in the upgrade plan isn't tagged.
# The tags, upgrade plan, and install plan are tables that use ":" and "#" to separate records and fields
# rather than newlines and spaces. This is because these values will be stored as single values in makefile
# variables, which cannot have spaces or newlines.
get_sqitch_info() {
    sqitch_directory=$1         # The directory where sqitch commands will be executed
    upgrade_plan_file_name=$2   # The name of the upgrade plan file in the sqitch directory
    install_plan_file_name=$3   # The name of the install plan file in the sqitch directory

    fake_tag="x.x.x"
    # Return the tag name and the file path of the sqitch deploy script for each record as two columns.
    # If the last record has no tag, then give it a fake tag "x.x.x", so that changes between the previous
    # tag and the end of the plan will be included in generated scripts.
    # Note: the tag name column (1st column) is blank except for on the specific records that are tagged.
    upgrade_plan=$(
        sqitch -C "$sqitch_directory" plan upgrade.plan --no-headers \
            --format format:"%t#$sqitch_directory/%F" \
        | awk \
            -v fake_tag=$fake_tag \
            '
            {
                gsub(/[[:space:]]+@/,"", $1);
                line[NR,1]=$1; line[NR,2]=$2
            }
            END {
                if (line[NR,1]=="") line[NR,1]=fake_tag;
                for (i=1;i<=NR;i++) printf("%s%s%s%s", line[i,1], OFS, line[i,2], ORS);
            }
        ' 'FS=#' 'ORS=:' 'OFS=#'
    )

    # Remove the "@" symbols that sqitch puts before the tag name.
    tags=$(
        sqitch -C $sqitch_directory tag $upgrade_plan_file_name \
        | awk '{gsub(/^@/,""); print}' 'ORS=:'
    )

    # The tag in the last record in the upgrade plan is the current version. If this tag is a fake tag, then
    # add the same fake tag to the list of tags.
    current_version=$(printf "%s" "$upgrade_plan" | awk 'END { print $1 }' 'FS=#' 'RS=:')
    if [ $current_version = $fake_tag ]
    then
        tags="$tags$fake_tag:"
    fi
    
    # Even though the install plan should not have any tags, the first column is still the tag column and
    # should therefore always be blank. This column is outputted for consistency, since functions are agnostic
    # to which kind of plan they operate on.
    install_plan=$(
        sqitch -C "$sqitch_directory" plan $install_plan_file_name --no-headers \
            --format format:"$sqitch_directory/%F" \
        | awk '{print "", $1}' 'ORS=:' 'OFS=#'
    )
    
    printf "%s" "$tags $upgrade_plan $install_plan $current_version"
}

# Get the paths of the SQL files that will be generated from the sqitch plans.
get_targets() {
    subset=$1               # Indicates whether to return the upgrade, downgrade, or install scripts.
    extension_name=$2       # The name of the postgresql extension. Used in the name of the returned scripts.
    targets_directory=$3    # The path to the directory where the scripts will be stored.
    tags=$(printf "%s" "$4" | awk '$1!="" {print $1}' 'RS=:' 'FS=#')     # The tags from get_sqitch_info().

    if [ $subset = "upgrade" ] || [ $subset = "downgrade" ]
    then
        if [ $subset = "downgrade" ]
        then
            # For a downgrade script, reverse the order of the tags, so that the tags are also reversed
            # in the name of the script.
            tags=$(printf "%s" "$tags" | awk '{lines[NR]=$0} END {for (i=NR;i>0;i--) printf("%s\n", lines[i])}')
        fi

        # For each tag after the first, output the path to a SQL script whose name contains the previous tag
        # name followed by the current tag name, e.g. .path/to/my_extension--1.0.0--1.0.1.sql
        start_tag=$(printf "%s" "$tags" | awk 'NR==1 {print $1}')
        for end_tag in $(printf "%s" "$tags" | awk 'NR!=1 {print $1}')
        do
            printf "%s" "$targets_directory/$extension_name--$start_tag--$end_tag.sql"
            start_tag=$end_tag
        done
    elif [ $subset = "install" ]
    then
        # The install script is named using the latest tag name.
        last_tag=$(printf "%s" "$tags" | awk 'END {print $1}')
        printf "%s" "$targets_directory/$extension_name--$last_tag.sql"
    else
        printf 'The target subset "%s" is not recognized.' "$subset" >&2
        exit 1
    fi
}

# Get the paths to the SQL files in the sqitch plan that should be combined to form the given upgrade or
# downgrade script.
get_upgrade_prerequisites() {
    extension_name=$1   # The name of the postgresql extension.
    current_target=$2   # The name of the upgrade or downgrade SQL script file being generated.
    # The upgrade plan from get_sqitch_info().
    sqitch_plan=$(printf "%s" "$3" | awk '{print $1, $2}' 'RS=:' 'FS=#' | awk '$1!="" {print $1, $2}' )

    # Parse the name of the upgrade/downgrade script to get the names of the versions that it will
    # upgrade/downgrade from and to.
    version_names=$(
        printf "%s" "$current_target" \
        | awk \
            -F-- \
            -v everything_before_version_strings="^.*$extension_name--" \
            '{gsub(/\.sql$/,"") gsub(everything_before_version_strings,"")} {print $1, $2}'
    )
    
    # Get the line numbers in the sqitch plan where the start and end versions of the upgrade/downgrade are.
    # Also get the number of lines in the plan, which will be used for recalculating the line numbers when
    # the plan is reversed to get records for a downgrade.
    version_lines=$(
        printf "%s" "$sqitch_plan" \
        | awk \
            -v start_version=$(printf "%s" "$version_names" | awk '{ print $1 }') \
            -v end_version=$(printf "%s" "$version_names" | awk '{ print $2 }') \
            '$1==start_version { start_line=NR } $1==end_version { end_line=NR }
            END { printf("%s %s %s", start_line, end_line, NR) }'
    )
    
    # If the first version line comes after the last version line, then this is a downgrade.
    if [ $(printf "%s" "$version_lines" | awk '$1>$2 { print 1; exit; } { print 2 }' ) -eq 1 ]
    then
        # Reverse the order of the plan records
        # Also switch from using "deploy" scripts to "revert" scripts, since this is a downgrade.
        sqitch_plan=$(
            printf "%s" "$sqitch_plan" \
            | awk '{ gsub("/deploy/", "/revert/", $0); lines[NR]=$0; } 
            END {for (i=NR;i>0;i--) printf("%s\n", lines[i])}')
        # Recalculate the lines where the upgrade/downgrade versions are in the reversed plan.
        version_lines=$(printf "%s" "$version_lines" | awk '{ printf("%s %s %s", $3-$1, $3-$2, $3) }')
    fi

    # Output all of the SQL file paths in the sqitch plan that correspond with the upgrade/downgrade.
    printf "%s" "$sqitch_plan" \
    | awk \
        -v start_version_line=$(printf "%s" "$version_lines" | awk '{ print $1 }') \
        -v end_version_line=$(printf "%s" "$version_lines" | awk '{ print $2 }') \
        'NR > start_version_line && NR <= end_version_line { print $NF } NR > end_version_line { exit }'
}

# Get all of the paths to the SQL files in the given plan.
get_all_prerequisites () {
    # The upgrade plan or install plan from get_sqitch_info().
    sqitch_plan=$(printf "%s" "$1" | awk '{print $1, $2}' 'RS=:' 'FS=#')

    printf "%s\n" "$sqitch_plan"
}

# Append one or more SQL files to a given target SQL file. Pass a region name to only append a certain
# region of the SQL files. A region in a SQL file is the space between these comment lines:
#   --#region my_region_name
#   --#endregion my_region_name
# (Note: the region comments must be at the beginning of the line with no whitespace before the "--".)
append_sql_files () {
    region_name=$1      # The name of the region in the SQL file to append. If "", then use the whole file.
    target_sql_file=$2  # The path to the file where the SQL files will be appended.
    shift 2
    input_sql_files=$@  # The paths to the SQL files to append.

    # Clear the contents of the target SQL file
    > $target_sql_file
    for sql_file in $input_sql_files
    do
        sql_file_content="$(cat $sql_file)"

        # If a region was specified, then get the start and end lines of the region in the SQL file.
        if [ -n "$region_name" ]
        then
            start_line=$(
                printf "%s" "$sql_file_content" \
                | awk \
                    -v region_pattern="^--#region[[:space:]]+$region_name([[:space:]]|$)" \
                    'BEGIN { IGNORECASE = 1 } $0 ~ region_pattern { print NR + 1 }'
            )
            end_line=$(
                printf "%s" "$sql_file_content" \
                | awk \
                    -v region_pattern="^--#endregion[[:space:]]+$region_name([[:space:]]|$)" \
                    'BEGIN { IGNORECASE = 1 } $0 ~ region_pattern { print NR - 1 }'
            )
        fi

        # If no region was specified or if the region was invalid, then the start and end lines are the
        # first and last lines in the SQL file.
        start_line=${start_line:-1}
        end_line=${end_line:-$(printf "%s" "$sql_file_content" | awk 'END { print NR }')}

        # Append the content of the SQL file from the start line to the end line. Exclude any region comments
        # if there happen to be any floating around in there.
        printf "%s\n" "$sql_file_content" \
        | awk \
            -v start_line=$start_line \
            -v end_line=$end_line \
            -v region_line_pattern="--#(end)?region" \
            'NR > end_line { exit } NR >= start_line && NR <= end_line && $0 !~ region_line_pattern { print }' \
        >> $target_sql_file
    done
}

# To use this script, pass the name of one of the above functions followed by the parameters for that function.
func_call=$1
shift
"$func_call" "$@"
