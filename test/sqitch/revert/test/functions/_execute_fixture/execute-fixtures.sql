-- Revert dream-db-extension-tests:functions/_execute_fixture/execute-fixtures from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__execute_fixtures();

COMMIT;
