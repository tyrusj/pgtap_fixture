-- Revert dream-db-extension-tests:functions/unconfigure_fixture/set-record-nulls from pg

BEGIN;

drop function unit_test.test_func_unconfig_fixture__set_record_nulls();

COMMIT;
