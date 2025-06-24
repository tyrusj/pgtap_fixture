-- Revert dream-db-extension-tests:functions/configure_fixture/null-fixture from pg

BEGIN;

drop function unit_test.test_func_config_fixture__null_fixture();

COMMIT;
