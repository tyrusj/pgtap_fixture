-- Revert dream-db-extension:functions/add_test_data/create from pg

BEGIN;
--#region exclude_transaction

drop function add_test_data(schema name, function name, parameters text, description text);

--#endregion exclude_transaction
COMMIT;
