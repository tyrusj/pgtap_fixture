-- Revert dream-db-extension-tests:test/functions/_execute_test/increment-test-number from pg

BEGIN;

drop function unit_test.test_func_execute_test__increment_test_number();

COMMIT;
