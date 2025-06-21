-- Deploy dream-db-extension:functions/_comment_line/create to pg

BEGIN;
--#region exclude_transaction

create function _comment_lines(str text, first_line integer default 1)
returns text
language plpgsql
immutable parallel safe
as
$$
declare line_start_pattern text := '^';
declare position_of_first_line_to_comment integer;
begin
    position_of_first_line_to_comment := regexp_instr(
        coalesce(str, ''),
        line_start_pattern,
        1,
        coalesce(first_line, 1),
        0,
        'n'
    );

    if position_of_first_line_to_comment = 0 then
        return str;
    else
        return regexp_replace(
            coalesce(str, ''),
            line_start_pattern,
            '# ',
            position_of_first_line_to_comment,
            0,
            'n'
        );
    end if;
end;
$$;

--#endregion exclude_transaction
COMMIT;
