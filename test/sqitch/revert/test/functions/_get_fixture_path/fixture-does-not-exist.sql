-- Revert dream-db-extension-tests:test/functions/_get_fixture_path/fixture-does-not-exist from pg

BEGIN;

drop function unit_test.test_func_get_path__fixture_does_not_exist();

COMMIT;
