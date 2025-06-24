-- Revert dream-db-provision:set-privs-on-public-schema from pg
\connect deploy_debug
BEGIN;

revoke create on schema public from nonadmin cascade;

COMMIT;
