-- Revert dream-db-extension:functions/remove_test_data/create from pg

BEGIN;
--#region exclude_transaction

drop function remove_test_data(schema name, function name, parameters text);

--#endregion exclude_transaction
COMMIT;
