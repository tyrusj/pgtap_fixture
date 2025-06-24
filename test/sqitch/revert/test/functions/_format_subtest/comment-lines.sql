-- Revert dream-db-extension-tests:test/functions/_format_subtest/comment-lines from pg

BEGIN;

drop function unit_test.test_func_format_subtest__comment_lines();

COMMIT;
