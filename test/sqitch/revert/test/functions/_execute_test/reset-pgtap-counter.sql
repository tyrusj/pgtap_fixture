-- Revert dream-db-extension-tests:test/functions/_execute_test/reset-pgtap-counter from pg

BEGIN;

drop function unit_test.test_func_execute_test__reset_pgtap_counter();

COMMIT;
