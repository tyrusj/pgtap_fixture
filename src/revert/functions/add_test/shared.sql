-- Revert dream-db-extension:functions/add_test/create from pg

BEGIN;
--#region exclude_transaction

drop function add_test(
    schema name,
    function name,
    description text,
    fixturePath text
);

--#endregion exclude_transaction
COMMIT;
