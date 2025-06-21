-- Revert dream-db-extension:functions/_format_subtest/create from pg

BEGIN;
--#region exclude_transaction

drop function _format_subtest(name text, description text);

--#endregion exclude_transaction
COMMIT;
