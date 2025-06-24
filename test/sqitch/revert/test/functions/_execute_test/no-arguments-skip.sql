-- Revert dream-db-extension-tests:test/functions/_execute_test/no-arguments-skip from pg

BEGIN;

drop function unit_test.test_func_execute_test__no_arguments_skip();

COMMIT;
