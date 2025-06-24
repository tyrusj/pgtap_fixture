-- Deploy dream-db-provision:set-privs-on-default-deploy-schema to pg
\connect install_debug
BEGIN;

grant all on schema nonpublic to nonadmin with grant option;

COMMIT;
