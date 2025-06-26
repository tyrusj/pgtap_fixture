-- Deploy dream-db-extension:functions/_format_skip/create to pg

BEGIN;
--#region exclude_transaction

create function _format_skip(ok boolean, num integer, name text, description text, reason text default null)
returns text
language sql
immutable parallel safe
begin atomic
    -- This pattern matches the first line, the new line character(s), and the remaining lines.
    with first_and_remaining_lines_pattern(p) as (select '(^[^\r\n]*)(\r\n|\r|\n)?(.*$)'),
    name_and_description_parts(p) as (
        select
            regexp_match(
                _escape_special_characters(coalesce(name, '') || ' ' || coalesce(description, '')),
                first_and_remaining_lines_pattern.p
            )
        from first_and_remaining_lines_pattern
    ),
    reason_parts(p) as (
        select
            regexp_match(
                _escape_special_characters(coalesce(reason, '')),
                first_and_remaining_lines_pattern.p
            )
        from first_and_remaining_lines_pattern
    ),
    -- Build the first line using only the first line from the name/description and the reason.
    first_line(p) as (
        select
            case when ok = true then 'ok' else 'not ok' end
            || ' ' || coalesce(num::text, '')
            || ' - ' || name_and_description_parts.p[1]
            || ' # skip'
            || case when reason_parts.p is null then ''
            else
                ' ' || reason_parts.p[1]
            end
        from name_and_description_parts, reason_parts
    ),
    -- If the name, description, or reason has a new line, use that character when adding new lines to the result.
    -- The intent is to avoid using the wrong kind of new line character. Any new line character in the arguments
    -- is probably more correct than this code assuming that \r\n or \n is correct.
    new_line(p) as (
        select coalesce(name_and_description_parts.p[2], reason_parts.p[2])
        from name_and_description_parts, reason_parts
    ),
    -- If the name/description or reason has more lines, then add those lines with labels indicating which text
    -- they are continuing.
    remaining_lines(p) as (
        select
            case when new_line.p is null then ''
            else 
                _comment_lines(
                    case when reason_parts.p[2] is null then ''
                    else
                        new_line.p || 'Reason cont''d: ' || reason_parts.p[3]
                    end
                    || case when name_and_description_parts.p[2] is null then ''
                    else
                        new_line.p || 'Name and description cont''d: ' || name_and_description_parts.p[3]
                    end
                , 2)
            end
        from new_line, reason_parts, name_and_description_parts
    )
    -- Combine the inputs into a string like the following
    -- not ok 17 - \#escaped name and description line 1 # skip \#escaped reason line 1
    -- # Reason cont'd: \#escaped reason line 2
    -- # \#escaped reason line 3
    -- # Name and description cont'd: \#escaped name and description line 2
    -- # \#escaped name and description line 3
    -- return first_line || remaining_lines;
    select first_line.p || remaining_lines.p
    from first_line, remaining_lines;
end;

comment on function _format_skip(ok boolean, num integer, name text, description text, reason text) is 
    $$Returns a string whose format complies with the TAP specification requirements for a skipped test.
    Arguments:
        ok: The test status.
        num: The test number.
        name: The test name.
        description: The test description.
        reason: The reason that the test was skipped.$$;

--#endregion exclude_transaction
COMMIT;
