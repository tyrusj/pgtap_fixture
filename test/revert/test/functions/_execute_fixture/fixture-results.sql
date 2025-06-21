-- Revert dream-db-extension-tests:test/functions/_execute_fixture/fixture-results from pg

BEGIN;

drop function unit_test.test_func_execute_fixture__fixture_results();

COMMIT;
