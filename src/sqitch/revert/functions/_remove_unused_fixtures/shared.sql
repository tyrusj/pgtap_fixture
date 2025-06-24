-- Revert dream-db-extension:functions/_remove_unused_fixtures/create from pg

BEGIN;
--#region exclude_transaction

drop function _remove_unused_fixtures(fixtureId integer);

--#endregion exclude_transaction
COMMIT;
