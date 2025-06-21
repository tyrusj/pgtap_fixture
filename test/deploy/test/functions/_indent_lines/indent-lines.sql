-- Deploy dream-db-extension-tests:test/functions/_indent_lines/indent-lines to pg

BEGIN;

create function unit_test.test_func_indent__indent_lines()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When indenting lines, for each line in the given string, the function shall insert a number of spaces
at the beginning of the line equal to 4 times the given degree.
$test_description$;
begin

    return query select tap.is(
        _indent_lines('Line one.', 1),
        '    Line one.',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Indent one line one degree.$scenario$)
    );

    return query select tap.is(
        _indent_lines('Line one.
Line two.', 1),
        '    Line one.
    Line two.',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Indent two lines one degree.$scenario$)
    );

    return query select tap.is(
        _indent_lines('Line one.
Line two.', 2),
        '        Line one.
        Line two.',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Indent two lines two degrees.$scenario$)
    );

end;
$$;

COMMIT;
