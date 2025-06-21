-- Deploy dream-db-extension:pgtap_wrappers/no_plan to pg

BEGIN;
--#region exclude_transaction

create function pgtap_no_plan()
returns setof boolean
language plpgsql
as
$$
begin
    return query select no_plan();
end;
$$;

--#endregion exclude_transaction
COMMIT;
