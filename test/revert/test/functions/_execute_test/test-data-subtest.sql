-- Revert dream-db-extension-tests:test/functions/_execute_test/test-data-subtest from pg

BEGIN;

drop function unit_test.test_func_execute_test__test_data_subtest();

COMMIT;
