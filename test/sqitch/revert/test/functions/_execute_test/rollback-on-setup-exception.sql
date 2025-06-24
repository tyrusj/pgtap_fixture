-- Revert dream-db-extension-tests:functions/_execute_test/rollback-on-setup-exception from pg

BEGIN;

drop function unit_test.test_func_execute_test__rollback_on_setup_exception();

COMMIT;
