-- Revert dream-db-extension:create-function-to-rollback from pg

BEGIN;
--#region exclude_transaction

drop function _function_rollback();

--#endregion exclude_transaction
COMMIT;
