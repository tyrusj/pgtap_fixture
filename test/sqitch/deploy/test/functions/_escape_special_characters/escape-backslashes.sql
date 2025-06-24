-- Deploy dream-db-extension-tests:test/functions/_escape_special_characters/escape-backslashes to pg

BEGIN;

create function unit_test.test_func_escape__escape_backslashes()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When escaping special characters, the function shall replace each '\' character in the given string with '\\'.
$test_description$;
begin

    return query select tap.is(
        _escape_special_characters('One \backslash'),
        'One \\backslash',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: One backslash in the middle of the string.$scenario$)
    );

    return query select tap.is(
        _escape_special_characters('One backslash\'),
        'One backslash\\',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: One backslash at the end of the string.$scenario$)
    );

    return query select tap.is(
        _escape_special_characters('\One backslash'),
        '\\One backslash',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: One backslash at the beginning of the string.$scenario$)
    );

    return query select tap.is(
        _escape_special_characters('\Multiple\ \backslashes\'),
        '\\Multiple\\ \\backslashes\\',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: Multiple backslashes.$scenario$)
    );

    return query select tap.is(
        _escape_special_characters('Multiple\\\backslashes'),
        'Multiple\\\\\\backslashes',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$5: Multiple adjacent backslashes.$scenario$)
    );

end;
$$;

COMMIT;
