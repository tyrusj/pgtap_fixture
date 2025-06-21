-- Revert dream-db-extension-tests:table-test-data-insert-unique-test-id-role-and-parameters from pg

BEGIN;

drop function unit_test.test_table_test_data_insert__unique_test_id_role_and_parameters();

COMMIT;
