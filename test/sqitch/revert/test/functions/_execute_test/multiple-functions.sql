-- Revert dream-db-extension-tests:test/functions/_execute_text/multiple-functions from pg

BEGIN;

drop function unit_test.test_func_execute_test__multiple_functions();

COMMIT;
