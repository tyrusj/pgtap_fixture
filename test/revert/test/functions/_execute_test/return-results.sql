-- Revert dream-db-extension-tests:functions/_execute_test/return-results from pg

BEGIN;

drop function unit_test.test_func_execute_test__return_results();

COMMIT;
