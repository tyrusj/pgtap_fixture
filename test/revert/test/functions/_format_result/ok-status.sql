-- Revert dream-db-extension-tests:test/functions/_format_result/ok-status from pg

BEGIN;

drop function unit_test.test_func_format_result__ok_status();

COMMIT;
