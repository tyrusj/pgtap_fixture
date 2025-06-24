-- Revert dream-db-extension-tests:functions/add_test/add-record from pg

BEGIN;

drop function unit_test.test_func_add_test__add_record();

COMMIT;
