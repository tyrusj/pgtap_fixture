-- Revert dream-db-extension-tests:test/functions/_get_fixture_path/return-path from pg

BEGIN;

drop function unit_test.test_func_get_path__return_path();

COMMIT;
