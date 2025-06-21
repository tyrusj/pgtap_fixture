-- Revert dream-db-extension:functions/_format_result/create from pg

BEGIN;
--#region exclude_transaction

drop function _format_result(ok boolean, num integer, name text, description text);

--#endregion exclude_transaction
COMMIT;
