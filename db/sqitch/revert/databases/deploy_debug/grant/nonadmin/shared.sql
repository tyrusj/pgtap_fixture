-- Revert dream-db-provision:set-deploy-privs from pg

BEGIN;

revoke all on database deploy_debug from nonadmin cascade;

COMMIT;
