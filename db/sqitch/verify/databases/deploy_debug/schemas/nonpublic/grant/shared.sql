-- Verify dream-db-provision:set-privs-on-default-deploy-schema on pg
\connect deploy_debug
BEGIN;

do
$$
declare _schema_name name := 'nonpublic';
declare _role_name name := 'nonadmin';
declare _expected_privileges text[] := array['CREATE', 'USAGE'];
declare _found_privileges text[];
begin
	select array_agg(acl.privilege_type) into _found_privileges
	from pg_catalog.pg_namespace ns
	cross join lateral aclexplode(ns.nspacl) acl(grantor, grantee, privilege_type, is_grantable)
	inner join pg_catalog.pg_roles rol
	on
		rol.oid = acl.grantee
	where
		ns.nspname = _schema_name
		and rol.rolname = _role_name
	group by rol.rolname
	;
	if 
		_found_privileges is null
		or not (
			_found_privileges @> _expected_privileges
			and _found_privileges <@ _expected_privileges
		)
	then
		raise $exception$Role "%" has the wrong privileges on schema "%".
Expected privileges: %
Actual privileges: %$exception$, _role_name, _schema_name, array_to_string(_expected_privileges, ','), array_to_string(_found_privileges, ',')
		;
	end if
	;
end;
$$;

ROLLBACK;
