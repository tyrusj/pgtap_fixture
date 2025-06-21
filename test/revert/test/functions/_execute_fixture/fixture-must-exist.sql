-- Revert dream-db-extension-tests:functions/_execute_fixture/fixture-must-exist from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__fixture_must_exist();

COMMIT;
