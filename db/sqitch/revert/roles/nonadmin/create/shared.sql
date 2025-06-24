-- Revert dream-db-provision:create-deploy-service-login from pg

BEGIN;

drop role nonadmin;

COMMIT;
