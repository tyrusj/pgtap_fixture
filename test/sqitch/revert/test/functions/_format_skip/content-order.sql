-- Revert dream-db-extension-tests:test/functions/_format_skip/content-order from pg

BEGIN;

drop function unit_test.test_func_format_skip__content_order();

COMMIT;
