-- Revert dream-db-extension-tests:test/functions/_execute_test/return-result from pg

BEGIN;

drop function unit_test.test_func_execute_test__return_status();

COMMIT;
