-- Revert dream-db-provision:create-default-schema-for-deploy-service from pg
\connect deploy_debug
BEGIN;

drop schema nonpublic;

COMMIT;
