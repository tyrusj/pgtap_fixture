-- Revert dream-db-extension-tests:test/functions/execute_tests/exception-bail-out from pg

BEGIN;

drop function unit_test.test_func_execute_tests__exception_bail_out();

COMMIT;
