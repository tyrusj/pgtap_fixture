-- Revert dream-db-extension-tests:functions/remove_all_test_data/remove-records from pg

BEGIN;

drop function unit_test.test_func_remove_all_data__remove_records();

COMMIT;
