-- Revert dream-db-extension:pgtap_wrappers/pgtap__cleanup from pg

BEGIN;
--#region exclude_transaction

drop function pgtap__cleanup();

--#endregion exclude_transaction
COMMIT;
