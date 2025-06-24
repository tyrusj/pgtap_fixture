-- Deploy dream-db-extension:create-function-to-validate-fixture-path to pg

BEGIN;
--#region exclude_transaction
drop function _is_fixture_path_valid(fixturePath text);
--#endregion exclude_transaction
COMMIT;
