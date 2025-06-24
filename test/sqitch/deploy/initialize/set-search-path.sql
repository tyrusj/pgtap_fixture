-- Deploy dream-db-extension-tests:set-search-path to pg

BEGIN;

do
$$
begin
execute format('alter role current_user in database %I set search_path to %s, tap', current_database(), current_setting('search_path'));
end;
$$;

COMMIT;
