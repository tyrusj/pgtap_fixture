-- Revert dream-db-extension-tests:functions/_execute_fixture/rollback-changes from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__rollback_changes();

COMMIT;
