-- Revert dream-db-extension-tests:functions/add_test/null-fixture from pg

BEGIN;

drop function unit_test.test_func_add_test__null_fixture();

COMMIT;
