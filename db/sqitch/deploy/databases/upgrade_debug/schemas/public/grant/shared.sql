-- Deploy dream-db-provision:set-privs-on-public-schema to pg
\connect upgrade_debug
BEGIN;

grant create on schema public to nonadmin;

COMMIT;
