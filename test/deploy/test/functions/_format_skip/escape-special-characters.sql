-- Deploy dream-db-extension-tests:test/functions/_format_skip/escape-special-characters to pg

BEGIN;

create function unit_test.test_func_format_skip__escape_special_characters()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When formatting a skipped test, the function shall escape special characters in the reason,
name, and description.
$test_description$;
begin

    return query select tap.is(
        _format_skip(true, 1, '#name\', '#description\', '#reason\'),
        'ok 1 - \#name\\ \#description\\ # skip \#reason\\',
        test_description
    );

end;
$$;

COMMIT;
