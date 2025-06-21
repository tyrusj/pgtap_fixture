-- Deploy dream-db-extension:functions/_indent_lines/create to pg

BEGIN;
--#region exclude_transaction

create function _indent_lines(str text, degree integer default 1)
returns text
language sql
immutable parallel safe
begin atomic
    
    -- Add spaces at the beginning of each line in the string. 4 spaces per degree.
    -- If the degree is null or less than 0, then don't add any spaces.
    return regexp_replace(
        coalesce(str, ''),
        '^',
        repeat(' ', coalesce(case when degree < 0 then 0 else degree end, 0) << 2),
        1,
        0,
        'n'
    );

end;

--#endregion exclude_transaction
COMMIT;
