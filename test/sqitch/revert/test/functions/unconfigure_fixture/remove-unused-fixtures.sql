-- Revert dream-db-extension-tests:functions/unconfigure_fixture/remove-unused-fixtures from pg

BEGIN;

drop function unit_test.test_func_unconfig_fixture__remove_unused_fixtures();

COMMIT;
