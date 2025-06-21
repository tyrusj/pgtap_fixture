-- Revert dream-db-extension-tests:table-fixture-insert-unique-name-and-parent from pg

BEGIN;

drop function unit_test.test_table_fixture_insert__unique_name_and_parent();

COMMIT;
