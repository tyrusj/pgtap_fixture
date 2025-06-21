-- Revert dream-db-extension:pgtap_wrappers/pgtap__restart_numb_seq from pg

BEGIN;
--#region exclude_transaction

drop function pgtap__restart_numb_seq();

--#endregion exclude_transaction
COMMIT;
