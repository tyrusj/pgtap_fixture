-- Revert dream-db-extension-tests:functions/add_test_data/create-record from pg

BEGIN;

drop function unit_test.test_func_add_data__create_record();

COMMIT;
