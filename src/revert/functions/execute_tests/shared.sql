-- Revert dream-db-extension:functions/execute_tests/create from pg

BEGIN;
--#region exclude_transaction

drop function execute_tests(fixturePaths text[], schema name, testFunctions text[]);

--#endregion exclude_transaction
COMMIT;
