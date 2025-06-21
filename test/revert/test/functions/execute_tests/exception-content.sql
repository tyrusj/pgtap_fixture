-- Revert dream-db-extension-tests:test/functions/execute_tests/exception-content from pg

BEGIN;

drop function unit_test.test_func_execute_tests__exception_content();

COMMIT;
