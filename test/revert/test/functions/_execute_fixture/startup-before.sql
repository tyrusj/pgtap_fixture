-- Revert dream-db-extension-tests:functions/_execute_fixture/startup-before from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__startup_before();

COMMIT;
