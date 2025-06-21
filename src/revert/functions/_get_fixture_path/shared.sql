-- Revert dream-db-extension:functions/_get_fixture_path/create from pg

BEGIN;
--#region exclude_transaction

drop function _get_fixture_path(fixture_id integer);

--#endregion exclude_transaction
COMMIT;
