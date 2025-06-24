-- Revert dream-db-extension-tests:test/functions/_format_subtest/content-order from pg

BEGIN;

drop function unit_test.test_func_format_subtest__content_order();

COMMIT;
