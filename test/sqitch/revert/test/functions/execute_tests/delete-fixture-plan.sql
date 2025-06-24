-- Revert dream-db-extension-tests:functions/execute_tests/delete-fixture-plan from pg

BEGIN;

drop function unit_test.test_func_execute_tests__delete_fixture_plan();

COMMIT;
