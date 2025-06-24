-- Revert dream-db-extension:create-fixture-plan-table from pg

BEGIN;
--#region exclude_transaction

drop table fixture_plan;

--#endregion exclude_transaction
COMMIT;
