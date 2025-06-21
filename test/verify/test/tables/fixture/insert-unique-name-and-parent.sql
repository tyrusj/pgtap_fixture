-- Verify dream-db-extension-tests:table-fixture-insert-unique-name-and-parent on pg

BEGIN;

do
$$
declare _expected_schema name := 'unit_test';
declare _expected_function_name name := 'test_table_fixture_insert__unique_name_and_parent';
declare _expected_function_arg_names text := '';
declare _found_arg_names text;
begin
	select
		case when count(*) > 0 then
			array_to_string(array_agg(typname), ', ', 'null') 
		else
			''
		end into _found_arg_names
	from (
		select typ.typname
		from pg_catalog.pg_proc proc
		cross join lateral unnest(proc.proargtypes) with ordinality argtyp(oid, idx)
		inner join pg_catalog.pg_type typ on typ.oid = argtyp.oid
		inner join pg_catalog.pg_namespace ns on ns.oid = proc.pronamespace
		where
			ns.nspname = _expected_schema
			and proc.proname = _expected_function_name
		order by argtyp.idx asc
	)
	;
	if _found_arg_names is null then
		raise 'Function "%" does not exist in schema "%".', _expected_function_name, _expected_schema;
	end if
	;
	if not _found_arg_names = _expected_function_arg_names
	then
		raise $exception$Function "%" has incorrect argument types:
Expected argument types: %
Actual argument types: %
$exception$, _expected_function_name, _expected_function_arg_names, _found_arg_names;
	end if
	;
end;
$$;

ROLLBACK;
