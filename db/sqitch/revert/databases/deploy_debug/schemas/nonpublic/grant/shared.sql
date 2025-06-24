-- Revert dream-db-provision:set-privs-on-default-deploy-schema from pg
\connect deploy_debug
BEGIN;

revoke all on schema nonpublic from nonadmin;

COMMIT;
