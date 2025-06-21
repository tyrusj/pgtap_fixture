-- Revert dream-db-extension-tests:test/functions/execute_tests/fixture-results from pg

BEGIN;

drop function unit_test.test_func_execute_tests__fixture_results();

COMMIT;
