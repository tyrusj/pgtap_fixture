-- Revert dream-db-extension-tests:functions/add_test/non-null-schema-and-function from pg

BEGIN;

drop function unit_test.test_func_add_test__non_null_schema_and_function();

COMMIT;
