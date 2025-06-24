-- Revert dream-db-extension-tests:functions/execute_tests/plan-given-fixtures from pg

BEGIN;

drop function unit_test.test_func_execute_tests__plan_given_fixtures();

COMMIT;
