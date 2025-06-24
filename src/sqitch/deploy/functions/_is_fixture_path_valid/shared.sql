-- Deploy dream-db-extension:create-function-to-validate-fixture-path to pg

BEGIN;
--#region exclude_transaction
create function _is_fixture_path_valid(fixturePath text)
returns bool
immutable parallel safe
language sql
return
    fixturePath not like '/%'
    and fixturePath not like '%/'
    and fixturePath not like '%//%'
;

comment on function _is_fixture_path_valid(fixturePath text) is
    $$Returns false if fixturePath is not a valid path. Paths must not begin or end with a slash character '/', nor can two slash characters be adjacent to one another, i.e. '//'.$$;
--#endregion exclude_transaction
COMMIT;
