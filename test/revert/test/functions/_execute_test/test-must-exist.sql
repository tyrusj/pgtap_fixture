-- Revert dream-db-extension-tests:functions/_execute_test/test-must-exist from pg

BEGIN;

drop function unit_test.test_func_execute_test__test_must_exist();

COMMIT;
