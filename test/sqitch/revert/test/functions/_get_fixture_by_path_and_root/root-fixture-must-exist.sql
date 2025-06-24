-- Revert dream-db-extension-tests:functions/_get_fixture_by_path_and_root/root-fixture-must-exist from pg

BEGIN;

drop function unit_test.test_func_get_fixture__root_fixture_must_exist();

COMMIT;
