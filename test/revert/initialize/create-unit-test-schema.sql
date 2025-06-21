-- Revert dream-db-extension-tests:create-unit-test-schema from pg

BEGIN;

drop schema unit_test;

COMMIT;
