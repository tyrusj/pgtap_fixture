-- Revert dream-db-extension-tests:functions/_is_fixture_path_valid/no-beginning-slash from pg

BEGIN;

drop function unit_test.test_func_valid_path__no_beginning_slash();

COMMIT;
