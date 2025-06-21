-- Revert dream-db-extension-tests:functions/remove_test_data/remove-record from pg

BEGIN;

drop function unit_test.test_func_remove_data__remove_record();

COMMIT;
