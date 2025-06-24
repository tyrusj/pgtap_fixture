-- Revert dream-db-extension-tests:test/functions/execute_tests/return-plan from pg

BEGIN;

drop function unit_test.test_func_execute_tests__return_plan();

COMMIT;
