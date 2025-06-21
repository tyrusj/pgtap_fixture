-- Revert dream-db-extension-tests:test/functions/_execute_test/function-does-not-exist from pg

BEGIN;

drop function unit_test.test_func_execute_test__function_does_not_exist();

COMMIT;
