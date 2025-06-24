-- Revert dream-db-extension-tests:functions/_execute_fixture/teardown-on-exception from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__teardown_on_startup_exception();

COMMIT;
