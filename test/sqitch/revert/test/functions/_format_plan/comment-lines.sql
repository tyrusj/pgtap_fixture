-- Revert dream-db-extension-tests:test/functions/_format_plan/comment-lines from pg

BEGIN;

drop function unit_test.test_func_format_plan__comment_lines();

COMMIT;
