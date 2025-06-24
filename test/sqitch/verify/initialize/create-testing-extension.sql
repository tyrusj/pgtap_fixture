-- Verify dream-db-extension-tests:create-testing-extension on pg

BEGIN;

do
$$
declare _expected_extension name := 'pgtap';
declare _found_extension name;
begin
    select extname into _found_extension
    from pg_catalog.pg_extension
    where extname = _expected_extension
    ;
    if not found then
        raise 'extension "%" was not found.', _expected_extension;
    end if
    ;
end;
$$;

ROLLBACK;
