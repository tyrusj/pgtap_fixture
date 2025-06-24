-- Deploy dream-db-extension-tests:test/functions/_format_plan/escape-special-characters to pg

BEGIN;

create function unit_test.test_func_format_plan__escape_special_characters()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When formatting a plan, the function shall escape special characters in the reason.
$test_description$;
begin

    return query select tap.is(
        _format_plan(3, '#reason\'),
        '1..3 # \#reason\\',
        test_description
    );

end;
$$;

COMMIT;
