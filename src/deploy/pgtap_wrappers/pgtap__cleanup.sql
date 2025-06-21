-- Deploy dream-db-extension:pgtap_wrappers/pgtap__cleanup to pg

BEGIN;
--#region exclude_transaction

create function pgtap__cleanup()
returns boolean
language plpgsql
as
$$
begin
    return _cleanup();
end;
$$;

--#endregion exclude_transaction
COMMIT;
