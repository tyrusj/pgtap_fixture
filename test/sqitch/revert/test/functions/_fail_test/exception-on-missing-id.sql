-- Revert dream-db-extension-tests:test/functions/_fail_test/exception-on-missing-id from pg

BEGIN;

drop function unit_test.test_func_fail_test__exception_on_missing_id();

COMMIT;
