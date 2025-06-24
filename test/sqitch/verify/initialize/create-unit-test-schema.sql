-- Verify dream-db-extension-tests:create-unit-test-schema on pg

BEGIN;

do
$$
declare _expected_schema name := 'unit_test';
declare _found_schema name;
begin
	select nspname into _found_schema
	from pg_catalog.pg_namespace
	where nspname = _expected_schema
	;
	if not found then
		raise 'Schema "%" not found', _expected_schema;
	end if
	;
end;
$$;

ROLLBACK;
