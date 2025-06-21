-- Deploy dream-db-extension:pgtap_wrappers/pgtap__get to pg

BEGIN;
--#region exclude_transaction

create function pgtap__get(text)
returns integer
language plpgsql
as
$$
begin
    return _get($1);
end;
$$;

--#endregion exclude_transaction
COMMIT;
