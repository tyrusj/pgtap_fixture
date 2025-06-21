-- Revert dream-db-extension:create-function-to-plan-child-tests-and-fixtures from pg

BEGIN;
--#region exclude_transaction

drop function _plan_child_tests_and_fixtures(fixtureId integer);

--#endregion exclude_transaction
COMMIT;
