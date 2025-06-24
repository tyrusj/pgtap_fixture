-- Deploy dream-db-provision:create-default-schema-for-deploy-service to pg
\connect upgrade_debug
BEGIN;

create schema nonpublic;

COMMIT;
