-- Deploy dream-db-extension:functions/_format_subtest/create to pg

BEGIN;
--#region exclude_transaction

create function _format_subtest(name text, description text)
returns text
-- language sql
language plpgsql
immutable parallel safe
-- begin atomic
as
$$
begin
    -- Combine the inputs into a string like the following
    -- # Subtest: \#escaped name \#escaped description
    return _comment_lines(
        '# Subtest: '
        || _escape_special_characters(
            coalesce(name, '')
            || ' ' || coalesce(description, '')
        )
        , 2
    );
end;
$$;

--#endregion exclude_transaction
COMMIT;
