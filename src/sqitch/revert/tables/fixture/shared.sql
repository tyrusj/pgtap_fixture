-- Revert dream-db-extension:create-fixutre-table from pg

BEGIN;
--#region exclude_transaction

drop table fixture;

--#endregion exclude_transaction
COMMIT;
