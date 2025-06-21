-- Revert dream-db-extension-tests:func-plan-parent-fixtures-include-parent-fixture from pg

BEGIN;

drop function unit_test.test_func_plan_parent_fixtures__include_parent_fixture();

COMMIT;
