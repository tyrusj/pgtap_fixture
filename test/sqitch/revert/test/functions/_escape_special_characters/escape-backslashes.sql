-- Revert dream-db-extension-tests:test/functions/_escape_special_characters/escape-backslashes from pg

BEGIN;

drop function unit_test.test_func_escape__escape_backslashes();

COMMIT;
