-- Revert dream-db-extension:create-function-to-plan-parent-fixtures from pg

BEGIN;
--#region exclude_transaction

drop function _plan_parent_fixtures(fixtureId integer);

--#endregion exclude_transaction
COMMIT;
