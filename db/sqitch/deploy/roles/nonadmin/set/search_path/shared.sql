-- Deploy dream-db-provision:set-deploy-service-search-path to pg

BEGIN;

alter role nonadmin set search_path = nonpublic, public;

COMMIT;
