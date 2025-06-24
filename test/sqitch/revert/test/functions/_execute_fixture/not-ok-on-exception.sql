-- Revert dream-db-extension-tests:test/functions/_execute_fixture/not-ok-on-exception from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__not_ok_on_exception();

COMMIT;
