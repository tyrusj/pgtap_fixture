-- Revert dream-db-extension:create-function-to-execute-fixture from pg

BEGIN;
--#region exclude_transaction

drop function _execute_fixture(fixtureId integer, num integer);

--#endregion exclude_transaction
COMMIT;
