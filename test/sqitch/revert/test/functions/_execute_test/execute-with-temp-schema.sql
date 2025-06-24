-- Revert dream-db-extension-tests:functions/_execute_test/execute-with-temp-schema from pg

BEGIN;

drop function unit_test.test_func_execute_test__execute_with_temp_schema();

COMMIT;
