-- Revert dream-db-extension:functions/_format_plan/create from pg

BEGIN;
--#region exclude_transaction

drop function _format_plan(num integer, reason text);

--#endregion exclude_transaction
COMMIT;
