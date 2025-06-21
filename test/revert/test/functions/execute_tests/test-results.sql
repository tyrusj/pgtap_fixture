-- Revert dream-db-extension-tests:test/functions/execute_tests/test-results from pg

BEGIN;

drop function unit_test.test_func_execute_tests__test_results();

COMMIT;
