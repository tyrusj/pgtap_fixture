-- Revert dream-db-extension-tests:test/functions/_format_plan/content-order-with-comment from pg

BEGIN;

drop function unit_test.test_func_format_plan__content_order_with_comment();

COMMIT;
