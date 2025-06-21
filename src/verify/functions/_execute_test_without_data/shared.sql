-- Verify dream-db-extension:functions/_execute_test_without_data/create on pg

BEGIN;

do
$$
declare _expected_schema name := current_schema();
declare _expected_function_name name := '_execute_test_without_data';
declare _expected_function_signatures text[] := array['int4, int4, text, text, text, text'];
declare _actual_function_signatures text[];
declare _error_message_missing_overloads text;
declare _error_message_actual_overloads text;
begin
	with function_signatures(sig) as (
		select
			array_to_string(array_agg(proctype.typname order by proctype.idx asc), ', ', '')
		from pg_catalog.pg_proc proc
		inner join pg_catalog.pg_namespace ns on ns.oid = proc.pronamespace
		left outer join lateral (
			select
				proc.oid proc_oid,
				typ.typname,
				argtyp.idx
			from unnest(proc.proargtypes) with ordinality argtyp(oid, idx)
			inner join pg_catalog.pg_type typ on typ.oid = argtyp.oid
		) proctype
		on proctype.proc_oid = proc.oid
		where
			ns.nspname = _expected_schema
			and proc.proname = _expected_function_name
		group by proc.oid
	)
	select array_agg(function_signatures.sig) from function_signatures
	into _actual_function_signatures
	;
	if _actual_function_signatures is null then
		raise 'Function "%" does not exist in schema "%".', _expected_function_name, _expected_schema;
	end if;

	if not _actual_function_signatures @> _expected_function_signatures then

		select string_agg('    (' || actual.sig || ')', E'\n')
		from unnest(_actual_function_signatures) actual(sig)
		into _error_message_actual_overloads
		;
		if _error_message_actual_overloads is null then _error_message_actual_overloads := '    (none)'; end if;

		select string_agg('    (' || expected.sig || ')', E'\n')
		from unnest(_expected_function_signatures) expected(sig)
		left outer join unnest(_actual_function_signatures) actual(sig) on actual.sig = expected.sig
		where actual.sig is null
		into _error_message_missing_overloads
		;

		raise
'Function %.% has missing overloads:
%
Found overloads:
%', 		quote_ident(_expected_schema),
			quote_ident(_expected_function_name),
			_error_message_missing_overloads, 
			_error_message_actual_overloads
		;

	end if;
end;
$$;

ROLLBACK;
