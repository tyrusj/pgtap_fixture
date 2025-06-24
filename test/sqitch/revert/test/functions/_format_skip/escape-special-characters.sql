-- Revert dream-db-extension-tests:test/functions/_format_skip/escape-special-characters from pg

BEGIN;

drop function unit_test.test_func_format_skip__escape_special_characters();

COMMIT;
