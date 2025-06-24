-- Revert dream-db-extension-tests:test/functions/execute_tests/increment-test-number from pg

BEGIN;

drop function unit_test.test_func_execute_tests__increment_test_number();

COMMIT;
