-- Revert dream-db-extension-tests:functions/add_test/no-duplicate-tests from pg

BEGIN;

drop function unit_test.test_func_add_test__no_duplicate_tests();

COMMIT;
