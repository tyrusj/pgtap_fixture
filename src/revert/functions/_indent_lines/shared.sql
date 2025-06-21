-- Revert dream-db-extension:functions/_indent_lines/create from pg

BEGIN;
--#region exclude_transaction

drop function _indent_lines(str text, degree integer);

--#endregion exclude_transaction
COMMIT;
