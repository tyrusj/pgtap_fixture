-- Revert dream-db-extension-tests:test/functions/_indent_lines/indent-lines from pg

BEGIN;

drop function unit_test.test_func_indent__indent_lines();

COMMIT;
