-- Revert dream-db-extension-tests:functions/plan-tests-and-fixtures/tests-must-exist from pg

BEGIN;

drop function unit_test.test_func_plan__tests_must_exist();

COMMIT;
