-- Revert dream-db-extension:functions/_fail_test from pg

BEGIN;
--#region exclude_transaction

drop function _fail_test(test_id integer, num integer, message text);

--#endregion exclude_transaction
COMMIT;
