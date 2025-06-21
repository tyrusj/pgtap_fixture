-- Revert dream-db-extension:functions/remove_test/create from pg

BEGIN;
--#region exclude_transaction

drop function remove_test(testSchema name, testFunction name);

--#endregion exclude_transaction
COMMIT;
