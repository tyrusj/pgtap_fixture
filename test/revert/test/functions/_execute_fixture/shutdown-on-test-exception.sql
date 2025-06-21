-- Revert dream-db-extension-tests:functions/_execute_fixture/shutdown-on-test-exception from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__shutdown_on_test_exception();

COMMIT;
