-- Revert dream-db-extension-tests:functions/_get_fixture_by_path_and_root/create-missing-fixtures from pg

BEGIN;

drop function unit_test.test_func_get_fixture__create_missing_fixtures();

COMMIT;
