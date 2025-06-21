-- Revert dream-db-extension:functions/_comment_line/create from pg

BEGIN;
--#region exclude_transaction

drop function _comment_lines(str text, first_line integer);

--#endregion exclude_transaction
COMMIT;
