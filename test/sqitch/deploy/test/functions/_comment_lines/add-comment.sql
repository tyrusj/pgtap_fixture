-- Deploy dream-db-extension-tests:test/functions/_comment_line/add-comment to pg

BEGIN;

create function unit_test.test_func_comment__add_comment()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When commenting lines, for each line in the given string, if that line's number is greater than or
equal to the given first line number, then the function shall insert '# ' at the beginning of that
line.
$test_description$;
begin

    return query select tap.is(
        _comment_lines('Line one.', null),
        '# Line one.',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: String has one line. Comment all lines.$scenario$)
    );

    return query select tap.is(
        _comment_lines(
'Line one.
Line two.', null),
'# Line one.
# Line two.',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: String has two lines. Comment all lines.$scenario$)
    );

    return query select tap.is(
        _comment_lines(null, null),
        null::text,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: String is null.$scenario$)
    );

    return query select tap.is(
        _comment_lines('Line one.', 2),
        'Line one.',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: String has one line. Comment line two which doesn't exist.$scenario$)
    );

    return query select tap.is(
        _comment_lines(
'Line one.
Line two.
Line three.', 2),
'Line one.
# Line two.
# Line three.',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: String has three lines. Comment lines two and three.$scenario$)
    );

end;
$$;

COMMIT;
