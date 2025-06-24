-- Revert dream-db-extension-tests:functions/_get_fixture_by_path_and_root/path-must-be-valid from pg

BEGIN;

drop function unit_test.test_func_get_fixture__path_must_be_valid();

COMMIT;
