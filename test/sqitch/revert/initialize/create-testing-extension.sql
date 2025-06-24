-- Revert dream-db-extension-tests:create-testing-extension from pg

BEGIN;

drop extension pgtap;

COMMIT;
