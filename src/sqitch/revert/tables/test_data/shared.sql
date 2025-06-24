-- Revert dream-db-extension:create-test-data-table from pg

BEGIN;
--#region exclude_transaction

drop table test_data;

--#endregion exclude_transaction
COMMIT;
