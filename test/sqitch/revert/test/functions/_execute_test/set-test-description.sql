-- Revert dream-db-extension-tests:functions/_execute_test/set-test-description from pg

BEGIN;

drop function unit_test.test_func_execute_test__set_test_description();

COMMIT;
