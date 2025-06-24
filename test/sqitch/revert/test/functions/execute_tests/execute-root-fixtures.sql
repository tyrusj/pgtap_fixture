-- Revert dream-db-extension-tests:functions/execute_tests/execute-root-fixtures from pg

BEGIN;

drop function unit_test.test_func_execute_tests__execute_root_fixtures();

COMMIT;
