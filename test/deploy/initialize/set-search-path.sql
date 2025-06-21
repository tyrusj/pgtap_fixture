-- Deploy dream-db-extension-tests:set-search-path to pg

BEGIN;

do
$$
begin
execute format('alter role current_user in database dream set search_path to %s, tap', current_setting('search_path'));
end;
$$;

COMMIT;
