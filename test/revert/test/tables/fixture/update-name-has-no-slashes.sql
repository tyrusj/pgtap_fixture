-- Revert dream-db-extension-tests:table-fixture-update-valid-name from pg

BEGIN;

drop function unit_test.test_table_fixture_update__valid_name();

COMMIT;
