-- Revert dream-db-extension-tests:test/functions/_execute_fixture/return-result from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__return_result();

COMMIT;
