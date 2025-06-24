-- Revert dream-db-extension-tests:functions/plan-tests-and-fixtures/include-test-parents-recursively from pg

BEGIN;

drop function unit_test.test_func_plan__include_test_parents_recursive();

COMMIT;
