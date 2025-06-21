-- Revert dream-db-extension-tests:test/functions/_format_skip/extra-reason-lines from pg

BEGIN;

drop function unit_test.test_func_format_skip__reason_lines();

COMMIT;
