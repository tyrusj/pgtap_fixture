-- Revert dream-db-extension-tests:functions/_execute_test/teardown-on-exception from pg

BEGIN;

drop function unit_test.test_func_execute_test__teardown_on_exception();

COMMIT;
