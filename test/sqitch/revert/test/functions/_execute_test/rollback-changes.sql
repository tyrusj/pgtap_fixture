-- Revert dream-db-extension-tests:functions/_execute_test/rollback-changes from pg

BEGIN;

drop function unit_test.test_func_execute_test__rollback_changes();

COMMIT;
