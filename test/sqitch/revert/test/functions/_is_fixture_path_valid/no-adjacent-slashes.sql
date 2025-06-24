-- Revert dream-db-extension-tests:functions/_is_fixture_path_valid/no-adjacent-slashes from pg

BEGIN;

drop function unit_test.test_func_valid_path__no_adjacent_slashes();

COMMIT;
