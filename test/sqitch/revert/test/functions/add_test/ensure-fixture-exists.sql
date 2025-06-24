-- Revert dream-db-extension-tests:functions/add_test/ensure-fixture-exists from pg

BEGIN;

drop function unit_test.test_func_add_test__ensure_fixture_exists();

COMMIT;
