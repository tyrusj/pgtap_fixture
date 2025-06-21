-- Revert dream-db-extension:pgtap_wrappers/pgtap__get from pg

BEGIN;
--#region exclude_transaction

drop function pgtap__get(text);

--#endregion exclude_transaction
COMMIT;
