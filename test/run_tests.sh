#!/bin/bash

# By default, run the tests for postres version 17
postgres_version=${1:-17}
# By default, run the tests in the upgrade_debug database
database_name=${2:-"upgrade_debug"}
# By default, run all of the tests. (All of the tests should begin with the text `test_`)
test_function_pattern=${3:-"^test_"}
# Get the directory where this script is located.
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

results_directory=$script_dir/results

case $postgres_version in
    17)
        connection_string=postgresql://nonadmin:password@localhost:5432
        ;;
    *)
        printf "Postgres version '%s' not recognized.\n" "$postgres_version" >&2
        exit 1
        ;;
esac

# Store test results as a text file in the results directory.
mkdir -p $results_directory
psql \
    -d $connection_string/$database_name \
    -c "select tap.runtests('unit_test', '$test_function_pattern');" \
    > $results_directory/postgres${postgres_version}_${database_name}.tap