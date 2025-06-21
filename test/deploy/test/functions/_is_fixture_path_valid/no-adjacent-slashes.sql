-- Deploy dream-db-extension-tests:functions/_is_fixture_path_valid/no-adjacent-slashes to pg

BEGIN;

create function unit_test.test_func_valid_path__no_adjacent_slashes()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When validating a fixture path, if the given fixture path contains two slash characters that are adjacent
to one another, then the function shall return false.
$test_description$;
declare test_id integer;
begin

    return query select tap.is(
        _is_fixture_path_valid('path//to/fixture'),
        false,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Two adjacent slash characters in the middle of the path. Expect false.$scenario$)
    );

    return query select tap.is(
        _is_fixture_path_valid('//path/to/fixture'),
        false,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Two adjacent slash characters at the beginning of the path. Expect false.$scenario$)
    );

    return query select tap.is(
        _is_fixture_path_valid('path/to/fixture//'),
        false,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Two adjacent slash characters at the end of the path. Expect false.$scenario$)
    );

    return query select tap.is(
        _is_fixture_path_valid('path/to///fixture'),
        false,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: Three adjacent slash characters. Expect false.$scenario$)
    );

    return query select tap.is(
        _is_fixture_path_valid('path/to/fixture'),
        true,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$5: Two non-adjacent slash characters. Expect true.$scenario$)
    );

    return query select tap.is(
        _is_fixture_path_valid('pathtofixture'),
        true,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$No slash characters. Expect true.$scenario$)
    );

    return query select tap.is(
        _is_fixture_path_valid('pathto/fixture'),
        true,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$7: One slash character. Expect true.$scenario$)
    );

end;
$$;

COMMIT;
