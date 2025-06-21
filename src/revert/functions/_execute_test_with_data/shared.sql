-- Revert dream-db-extension:functions/_execute_test_with_data/create from pg

BEGIN;
--#region exclude_transaction

drop function _execute_test_with_data(
    test_id integer,
    num integer,
    qualified_function text,
    test_description text,
    fixture_setup text,
    fixture_teardown text
);

--#endregion exclude_transaction
COMMIT;
