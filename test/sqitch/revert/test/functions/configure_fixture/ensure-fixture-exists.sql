-- Revert dream-db-extension-tests:functions/configure_fixture/ensure-fixture-exists from pg

BEGIN;

drop function unit_test.test_func_config_fixture__ensure_fixture_exists();

COMMIT;
