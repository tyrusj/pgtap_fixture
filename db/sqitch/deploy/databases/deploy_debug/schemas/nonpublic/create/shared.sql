-- Deploy dream-db-provision:create-default-schema-for-deploy-service to pg
\connect deploy_debug
BEGIN;

create schema nonpublic;

COMMIT;
