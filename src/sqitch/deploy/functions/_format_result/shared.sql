-- Deploy dream-db-extension:functions/_format_result/create to pg

BEGIN;
--#region exclude_transaction

create function _format_result(ok boolean, num integer, name text, description text)
returns text
language sql
begin atomic
    -- Combine the inputs into a string like the following
    -- not ok 17 - \#escaped name \#escaped description
    return _comment_lines(
        case when ok = true then 'ok' else 'not ok' end
        || ' ' || coalesce(num::text, '')
        || ' - ' || _escape_special_characters(
            coalesce(name, '')
            || ' ' || coalesce(description, '')
        )
        , 2
    );
end;

--#endregion exclude_transaction
COMMIT;
