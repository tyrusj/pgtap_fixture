-- Revert dream-db-extension-tests:functions/_execute_test/teardown-after-test from pg

BEGIN;

drop function unit_test.test_func_execute_test__teardown_after_test();

COMMIT;
