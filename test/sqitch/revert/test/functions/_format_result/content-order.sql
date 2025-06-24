-- Revert dream-db-extension-tests:text/functions/_format_result/content-order from pg

BEGIN;

drop function unit_test.test_func_format_result__content_order();

COMMIT;
