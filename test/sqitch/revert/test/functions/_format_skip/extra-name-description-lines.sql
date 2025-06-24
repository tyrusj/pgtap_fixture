-- Revert dream-db-extension-tests:test/functions/_format_skip/extra-name-description-lines from pg

BEGIN;

drop function unit_test.test_func_format_skip__name_description_lines();

COMMIT;
