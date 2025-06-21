-- Revert dream-db-extension-tests:table-fixture-update-name-not-zero-length from pg

BEGIN;

drop function unit_test.test_table_fixture_update__name_not_zero_length();

COMMIT;
