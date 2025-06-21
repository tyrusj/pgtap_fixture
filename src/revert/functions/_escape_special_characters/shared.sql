-- Revert dream-db-extension:functions/_escape_special_characters/create from pg

BEGIN;
--#region exclude_transaction

drop function _escape_special_characters(str text);

--#endregion exclude_transaction
COMMIT;
