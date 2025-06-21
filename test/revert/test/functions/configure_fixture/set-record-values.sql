-- Revert dream-db-extension-tests:functions/configure_fixture/set-record-values from pg

BEGIN;

drop function unit_test.test_func_config_fixture__set_record_values();

COMMIT;
