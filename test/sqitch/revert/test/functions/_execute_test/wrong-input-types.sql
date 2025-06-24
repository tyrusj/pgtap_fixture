-- Revert dream-db-extension-tests:test/functions/_execute_test/wrong-input-types from pg

BEGIN;

drop function unit_test.test_func_execute_test__wrong_input_types();

COMMIT;
