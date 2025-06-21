-- Deploy dream-db-extension:pgtap_wrappers/pgtap__set to pg

BEGIN;
--#region exclude_transaction

create function pgtap__set(text, integer)
returns integer
language plpgsql
as
$$
begin
    return _set($1, $2);
end;
$$;

create function pgtap__set(text, integer, text)
returns integer
language plpgsql
as
$$
begin
    return _set($1, $2, $3);
end;
$$;

--#endregion exclude_transaction
COMMIT;
