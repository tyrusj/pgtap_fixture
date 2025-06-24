-- Revert dream-db-extension:pgtap_wrappers/no_plan from pg

BEGIN;
--#region exclude_transaction

drop function pgtap_no_plan();

--#endregion exclude_transaction
COMMIT;
