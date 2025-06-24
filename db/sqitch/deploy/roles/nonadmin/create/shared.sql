-- Deploy dream-db-provision:create-deploy-service-login to pg

BEGIN;

create role nonadmin with login createrole
password 'password';

COMMIT;
