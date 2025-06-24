-- Deploy dream-db-provision:set-privs-on-public-schema to pg
\connect deploy_debug
BEGIN;

grant create on schema public to nonadmin;

COMMIT;
