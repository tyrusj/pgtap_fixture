-- Revert dream-db-extension:create-function-to-plan-tests-and-fixtures from pg

BEGIN;
--#region exclude_transaction

drop function _plan_tests_and_fixtures(fixtureIds integer[], testIds integer[]);

--#endregion exclude_transaction
COMMIT;
