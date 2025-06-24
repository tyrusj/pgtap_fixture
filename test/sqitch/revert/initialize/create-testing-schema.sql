-- Revert dream-db-extension-tests:create-testing-schema from pg

BEGIN;

drop schema tap;

COMMIT;
