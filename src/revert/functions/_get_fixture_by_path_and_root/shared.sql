-- Revert dream-db-extension:functions/_get_fixture_by_path_and_root/create from pg

BEGIN;
--#region exclude_transaction

drop function _get_fixture_by_path_and_root(
    fixturePath text,
    root integer,
    createMissingFixtures boolean
);

--#endregion exclude_transaction
COMMIT;
