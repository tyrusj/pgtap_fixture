-- Revert dream-db-extension-tests:set-search-path from pg

BEGIN;

do
$$
begin
    execute format('alter role current_user in database %I reset search_path', current_database());
end;
$$;

COMMIT;
