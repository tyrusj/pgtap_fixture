-- Deploy dream-db-extension:functions/_escape_special_characters/create to pg

BEGIN;
--#region exclude_transaction

create function _escape_special_characters(str text)
returns text
language sql
immutable parallel safe strict
begin atomic
    return replace(
        replace(
            str, '\', '\\'
        ), '#', '\#'
    );
end;

--#endregion exclude_transaction
COMMIT;
