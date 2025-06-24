-- Revert dream-db-extension-tests:functions/_execute_fixture/teardown-after from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__teardown_after();

COMMIT;
