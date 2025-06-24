-- Verify dream-db-provision:create-default-schema-for-deploy-service on pg
\connect upgrade_debug
BEGIN;

do
$$
declare _expected_schema name := 'nonpublic';
declare _found_schema name;
begin
	select nspname into _found_schema
	from pg_catalog.pg_namespace
	where nspname = _expected_schema
	;
	if not found then
		raise 'Schema "%" not found.', _expected_schema;
	end if
	;
end;
$$;

ROLLBACK;
