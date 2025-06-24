-- Revert dream-db-extension-tests:test/functions/_execute_fixture/return-subtest from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__return_subtest();

COMMIT;
