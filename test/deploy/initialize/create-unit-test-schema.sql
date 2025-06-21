-- Deploy dream-db-extension-tests:create-unit-test-schema to pg

BEGIN;

create schema unit_test;

COMMIT;
