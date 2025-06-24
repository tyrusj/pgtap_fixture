-- Revert dream-db-extension-tests:functions/plan-tests-and-fixtures/fixtures-must-exist from pg

BEGIN;

drop function unit_test.test_func_plan__fixtures_must_exist();

COMMIT;
