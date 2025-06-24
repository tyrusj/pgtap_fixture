-- Deploy dream-db-extension-tests:test/functions/_format_result/escape-special-characters to pg

BEGIN;

create function unit_test.test_func_format_result__escape_special_characters()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When formatting a result, the function shall escape special characters in the name and description.
$test_description$;
begin

    return query select tap.is(
        _format_result(true, 1, '#name\', '#description\'),
        'ok 1 - \#name\\ \#description\\',
        test_description
    );

end;
$$;

COMMIT;
