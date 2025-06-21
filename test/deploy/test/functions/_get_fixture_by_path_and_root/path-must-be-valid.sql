-- Deploy dream-db-extension-tests:functions/_get_fixture_by_path_and_root/path-must-be-valid to pg

BEGIN;

create function unit_test.test_func_get_fixture__path_must_be_valid()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When getting a fixture by path and root, if the given fixture path is not valid, then the function
shall throw an exception.
$test_description$;
begin

    return query select tap.throws_ok(
        $throws$select _get_fixture_by_path_and_root('//invalid//fixture//path//', 0);$throws$,
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Execute with an invalid fixture path. Expect exception.$scenario$)
    );

    return query select tap.throws_ok(
        $throws$select _get_fixture_by_path_and_root(null, null);$throws$,
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Execute with a null fixture path. Expect exception.$scenario$)
    );

end;
$$;

COMMIT;
