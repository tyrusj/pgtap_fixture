-- Revert dream-db-extension-tests:test/functions/_format_plan/escape-special-characters from pg

BEGIN;

drop function unit_test.test_func_format_plan__escape_special_characters();

COMMIT;
