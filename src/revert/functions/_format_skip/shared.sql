-- Revert dream-db-extension:functions/_format_skip/create from pg

BEGIN;
--#region exclude_transaction

drop function _format_skip(ok boolean, num integer, name text, description text, reason text);

--#endregion exclude_transaction
COMMIT;
