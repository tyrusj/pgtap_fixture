-- Revert dream-db-extension:create-function-to-execute-tests-with-data from pg

BEGIN;
--#region exclude_transaction

drop function _execute_test(testId integer, num integer);

--#endregion exclude_transaction
COMMIT;
