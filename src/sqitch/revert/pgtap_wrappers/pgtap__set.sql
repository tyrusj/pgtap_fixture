-- Revert dream-db-extension:pgtap_wrappers/pgtap__set from pg

BEGIN;
--#region exclude_transaction

drop function pgtap__set(text, integer);
drop function pgtap__set(text, integer, text);

--#endregion exclude_transaction
COMMIT;
