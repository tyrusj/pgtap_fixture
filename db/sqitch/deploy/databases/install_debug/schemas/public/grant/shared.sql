-- Deploy dream-db-provision:set-privs-on-public-schema to pg
\connect install_debug
BEGIN;

grant create on schema public to nonadmin;

COMMIT;
