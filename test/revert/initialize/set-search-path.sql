-- Revert dream-db-extension-tests:set-search-path from pg

BEGIN;

alter role current_user in database dream reset search_path;

COMMIT;
