-- Verify dream-db-provision:set-privs-on-public-schema on pg
\connect install_debug
BEGIN;

do
$$
declare _schema_name name := 'public';
declare _role_name name := 'nonadmin';
declare _expected_privilege text := 'CREATE';
declare _found_privilege text;
begin
	select acl.privilege_type into _found_privilege
	from pg_catalog.pg_namespace ns
	cross join lateral aclexplode(ns.nspacl) acl(grantor, grantee, privilege_type, is_grantable)
	inner join pg_catalog.pg_roles rol
	on
		rol.oid = acl.grantee
	where
		ns.nspname = _schema_name
		and rol.rolname = _role_name
		and acl.privilege_type = _expected_privilege
	;
	if not found then
		raise 'Role "%" does not have "%" privilege on schema "%".', _role_name, _expected_privilege, _schema_name;
	end if
	;
end;
$$;

ROLLBACK;
