-- Revert dream-db-extension-tests:func-plan-parent-fixture-recursively-plan-parent-fixtures from pg

BEGIN;

drop function unit_test.test_func_plan_parent_fixtures__recursively_plan_fixtures();

COMMIT;
