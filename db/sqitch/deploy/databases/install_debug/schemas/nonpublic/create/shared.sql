-- Deploy dream-db-provision:create-default-schema-for-deploy-service to pg
\connect install_debug
BEGIN;

create schema nonpublic;

COMMIT;
