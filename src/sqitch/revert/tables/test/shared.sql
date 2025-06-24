-- Revert dream-db-extension:create-test-table from pg

BEGIN;
--#region exclude_transaction

drop table test;

--#endregion exclude_transaction
COMMIT;
