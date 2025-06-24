-- Revert dream-db-extension-tests:functions/_execute_test/setup-before-test from pg

BEGIN;

drop function unit_test.test_func_execute_test__setup_before_test();

COMMIT;
