-- Deploy dream-db-extension-tests:functions/_is_fixture_path_valid/no-ending-slash to pg

BEGIN;

create function unit_test.test_func_valid_path__no_ending_slash()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When validating a fixture path, if the given fixture path ends with a slash character, then the
function shall return false.
$test_description$;
declare test_id integer;
begin

    return query select tap.is(
        _is_fixture_path_valid('path/to/fixture/'),
        false,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: End with slash with multiple slashes. Expect false.$scenario$)
    );

    return query select tap.is(
        _is_fixture_path_valid('pathtofixture/'),
        false,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: End with slash with no other slashes. Expect false.$scenario$)
    );

    return query select tap.is(
        _is_fixture_path_valid('pathtofixtur/e'),
        true,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: End with slash followed by a character. Expect true.$scenario$)
    );

end;
$$;

COMMIT;
