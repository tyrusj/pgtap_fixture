-- Revert dream-db-extension-tests:table-test-update-unique-schema-and-function from pg

BEGIN;

drop function unit_test.test_table_test_update__unique_schema_and_function();

COMMIT;
