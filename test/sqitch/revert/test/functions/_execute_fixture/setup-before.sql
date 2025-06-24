-- Revert dream-db-extension-tests:functions/_execute_fixture/setup-before from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__setup_before();

COMMIT;
