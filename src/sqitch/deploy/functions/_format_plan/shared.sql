-- Deploy dream-db-extension:functions/_format_plan/create to pg

BEGIN;
--#region exclude_transaction

create function _format_plan(num integer, reason text default null)
returns text
language sql
immutable parallel safe
begin atomic
    -- Combine the inputs into a string like the following
    -- 1..7 # \#escaped reason
    return _comment_lines(
        '1..'
        || coalesce(num::text, '')
        || case when reason is null then '' else
            ' # '
            || _escape_special_characters(reason)
        end
        , 2
    );
end;

--#endregion exclude_transaction
COMMIT;
