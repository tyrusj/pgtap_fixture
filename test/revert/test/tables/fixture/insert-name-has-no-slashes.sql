-- Revert dream-db-extension-tests:table-fixture-insert-valid-name from pg

BEGIN;

drop function unit_test.test_table_fixture_insert__valid_name();

COMMIT;
