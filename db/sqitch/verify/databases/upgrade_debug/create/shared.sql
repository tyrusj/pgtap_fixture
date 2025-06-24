-- Verify dream-db-provision:create-database on pg

BEGIN;

do
$$
declare _database_name name := 'upgrade_debug';
declare _found_database name;
begin
	select datname into _found_database
	from pg_catalog.pg_database
	where datname = _database_name
	;
	if not found then
		raise 'Failed to create database "%"', _database_name;
	end if
	;
end;
$$;

ROLLBACK;
