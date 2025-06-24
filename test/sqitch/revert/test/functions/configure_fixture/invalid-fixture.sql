-- Revert dream-db-extension-tests:functions/configure_fixture/invalid-fixture from pg

BEGIN;

drop function unit_test.test_func_config_fixture__invalid_fixture();

COMMIT;
