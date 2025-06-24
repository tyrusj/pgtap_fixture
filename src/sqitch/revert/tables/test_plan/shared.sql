-- Revert dream-db-extension:create-test-plan-table from pg

BEGIN;
--#region exclude_transaction

drop table test_plan;

--#endregion exclude_transaction
COMMIT;
