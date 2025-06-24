-- Verify dream-db-provision:create-deploy-service-login on pg

BEGIN;

do
$$
declare _role_name name := 'nonadmin';
declare _found_role_name name;
begin
	select rolname into _found_role_name
	from pg_catalog.pg_roles
	where rolname = _role_name
	;
	if not found then
		raise 'Failed to create role "%".', _role_name;
	end if
	;
end;
$$;

ROLLBACK;
