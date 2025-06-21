-- Revert dream-db-extension-tests:test/functions/_fail_test/return-plan from pg

BEGIN;

drop function unit_test.test_func_fail_test__return_plan();

COMMIT;
