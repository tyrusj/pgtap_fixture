-- Revert dream-db-extension-tests:functions/execute_tests/delete-test-plan from pg

BEGIN;

drop function unit_test.test_func_execute_tests__delete_test_plan();

COMMIT;
