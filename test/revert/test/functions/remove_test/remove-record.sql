-- Revert dream-db-extension-tests:functions/remove_test/remove-record from pg

BEGIN;

drop function unit_test.test_func_remove_test__remove_record();

COMMIT;
