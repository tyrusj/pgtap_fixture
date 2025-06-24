-- Revert dream-db-extension-tests:test/functions/_comment_line/add-comment from pg

BEGIN;

drop function unit_test.test_func_comment__add_comment();

COMMIT;
