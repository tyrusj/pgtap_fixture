-- Revert dream-db-extension-tests:functions/add_test_data/test-must-exist from pg

BEGIN;

drop function unit_test.test_func_add_data__test_must_exist();

COMMIT;
