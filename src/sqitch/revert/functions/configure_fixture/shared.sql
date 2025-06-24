-- Revert dream-db-extension:functions/configure_fixture/create from pg

BEGIN;
--#region exclude_transaction

drop function configure_fixture(
    fixturePath text,
    description text,
    startup text,
    shutdown text,
    setup text,
    teardown text
);

--#endregion exclude_transaction
COMMIT;
