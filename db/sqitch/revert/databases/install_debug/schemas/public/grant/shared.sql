-- Revert dream-db-provision:set-privs-on-public-schema from pg
\connect install_debug
BEGIN;

revoke create on schema public from nonadmin cascade;

COMMIT;
