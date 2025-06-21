-- Revert dream-db-extension-tests:func-plan-parent-fixtures-fixture-must-exist from pg

BEGIN;

drop function unit_test.test_func_plan_parent_fixtures__fixture_must_exist();

COMMIT;
