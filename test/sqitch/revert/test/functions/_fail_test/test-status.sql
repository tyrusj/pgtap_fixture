-- Revert dream-db-extension-tests:test/functions/_fail_test/test-status from pg

BEGIN;

drop function unit_test.test_func_fail_test__test_status();

COMMIT;
