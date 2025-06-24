-- Revert dream-db-provision:set-deploy-service-search-path from pg

BEGIN;

alter role nonadmin reset search_path;

COMMIT;
