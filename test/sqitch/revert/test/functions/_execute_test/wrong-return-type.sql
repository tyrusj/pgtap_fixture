-- Revert dream-db-extension-tests:test/functions/_execute_test/wrong-return-type from pg

BEGIN;

drop function unit_test.test_func_execute_test__wrong_return_type();

COMMIT;
