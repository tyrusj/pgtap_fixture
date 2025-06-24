-- Revert dream-db-extension-tests:test/functions/execute_tests/missing-fixture-bail-out from pg

BEGIN;

drop function unit_test.test_func_execute_tests__missing_fixture_bail_out();

COMMIT;
