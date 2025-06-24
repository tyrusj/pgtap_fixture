-- Revert dream-db-extension-tests:table-fixture-insert-name-not-zero-length from pg

BEGIN;

drop function unit_test.test_table_fixture_insert__name_not_zero_length();

COMMIT;
