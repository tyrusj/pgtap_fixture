-- Revert dream-db-extension-tests:functions/_execute_test/execute-with-no-arguments from pg

BEGIN;

drop function unit_test.test_func_execute_test__execute_with_no_arguments();

COMMIT;
