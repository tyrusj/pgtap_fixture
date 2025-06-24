-- Verify dream-db-extension:create-test-data-table on pg

BEGIN;

do
$$
declare _expected_table name := 'test_data';
declare _expected_database name := current_database();
declare _expected_schema name := current_schema();
declare _found_table name;
begin
	select table_name into _found_table
	from information_schema.tables
	where
		table_catalog = _expected_database
		and table_schema = _expected_schema
		and table_name = _expected_table
	;
	if not found then
		raise 'Table %.% not found in database %.', _expected_schema, _expected_table, _expected_database;
	end if
	;
end;
$$;

ROLLBACK;
