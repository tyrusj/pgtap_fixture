-- Revert dream-db-extension-tests:functions/_remove_unused_fixtures/remove-parent-fixture from pg

BEGIN;

drop function unit_test.test_func_unused_fixtures__remove_parent_fixture();

COMMIT;
