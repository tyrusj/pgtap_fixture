-- Revert dream-db-extension:functions/remove_all_test_data/create from pg

BEGIN;
--#region exclude_transaction

drop function remove_all_test_data(schema name, function name);

--#endregion exclude_transaction
COMMIT;
