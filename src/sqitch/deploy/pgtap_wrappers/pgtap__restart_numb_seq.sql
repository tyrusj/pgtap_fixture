-- Deploy dream-db-extension:pgtap_wrappers/pgtap__restart_numb_seq to pg

BEGIN;
--#region exclude_transaction

create function pgtap__restart_numb_seq()
returns void
language plpgsql
as
$$
begin
    EXECUTE 'ALTER SEQUENCE __tresults___numb_seq RESTART WITH 1';
end;
$$;

--#endregion exclude_transaction
COMMIT;
