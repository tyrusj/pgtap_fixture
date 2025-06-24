-- Revert dream-db-extension-tests:test/functions/_execute_fixture/skip-empty from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__skip_empty();

COMMIT;
