-- Verify dream-db-provision:set-deploy-service-search-path on pg

BEGIN;

do
$$
declare _role_name name := 'nonadmin';
declare _expected_search_path text := 'nonpublic, public';
declare _found_search_paths _text;
declare _expected_search_path_formated text := format('search_path=%s', _expected_search_path);
begin
	select rol.rolconfig into _found_search_paths
	from pg_catalog.pg_roles rol
	where rol.rolname = _role_name
	;
	if not _found_search_paths @>  array[_expected_search_path_formated] then
		raise $exception$Role "%" does not have the expected search path:
Expected search path: %
Actual search paths: %
$exception$, _role_name, _expected_search_path, array_to_string(_found_search_paths, ';', 'null');
	end if
	;
end;
$$;

ROLLBACK;
