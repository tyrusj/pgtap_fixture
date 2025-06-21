-- Deploy dream-db-extension:create-function-to-rollback to pg

BEGIN;
--#region exclude_transaction

create function _function_rollback()
returns void
language plpgsql
as
$$
begin
    raise 'Intentional exception to force transaction rollback.' using errcode = 'TJ1A0';
end;
$$;

comment on function _function_rollback() is
    $$This function raises an exception and is used to intentionally roll back changes. It uses error code 'TJ1A0'. Catch and ignore this error code after executing this function.$$;

--#endregion exclude_transaction
COMMIT;
