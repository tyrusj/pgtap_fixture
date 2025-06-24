-- Deploy dream-db-extension-tests:create-testing-extension to pg

BEGIN;

create extension pgtap with schema tap;

COMMIT;
