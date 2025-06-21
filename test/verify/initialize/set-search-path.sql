-- Verify dream-db-extension-tests:set-search-path on pg

BEGIN;

do
$$
declare _expected_search_path_pattern text := '^.*, tap$';
declare _role_name name := current_user;
declare _database_name name := current_database();
declare _found_search_path text;
begin
	select config.search_path into _found_search_path
	from pg_catalog.pg_db_role_setting rs
	inner join  pg_catalog.pg_roles rol
	on rol.oid = rs.setrole
    inner join pg_catalog.pg_database db
    on db.oid = rs.setdatabase
    cross join lateral (
        select substring(config.setting from '^search_path=(.*)$') as search_path
        from unnest(rs.setconfig) config(setting)
        where config.setting ~ '^search_path='
    ) config
	where
        rol.rolname = _role_name
        and db.datname = _database_name
	;

	if not _found_search_path ~ _expected_search_path_pattern then
		raise $exception$Role "%" does not have the expected search path:
Expected search path pattern: %
Actual search path: %
$exception$, _role_name, _expected_search_path_pattern, _found_search_path;
	end if
	;
end;
$$;

ROLLBACK;
