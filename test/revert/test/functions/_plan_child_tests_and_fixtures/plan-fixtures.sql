-- Revert dream-db-extension-tests:functions/plan-child-tests-and-fixtures/plan-fixtures from pg

BEGIN;

drop function unit_test.test_func_plan_children__plan_fixtures();

COMMIT;
