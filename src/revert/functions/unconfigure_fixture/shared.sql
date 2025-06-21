-- Revert dream-db-extension:functions/unconfigure_fixture/create from pg

BEGIN;
--#region exclude_transaction

drop function unconfigure_fixture(fixturePath text);

--#endregion exclude_transaction
COMMIT;
