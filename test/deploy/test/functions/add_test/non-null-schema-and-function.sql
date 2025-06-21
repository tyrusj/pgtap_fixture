-- Deploy dream-db-extension-tests:functions/add_test/non-null-schema-and-function to pg

BEGIN;

create function unit_test.test_func_add_test__non_null_schema_and_function()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When adding a test, if the given schema or function is null, then the function shall throw an exception.
$test_description$;
begin

    return query select tap.throws_ok(
        $throws$select add_test(null, 'my_function');$throws$,
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Add a test with a null schema. Expect exception.$scenario$)
    );

    return query select tap.throws_ok(
        $throws$select add_test('my_schema', null);$throws$,
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Add a test with a null function name. Expect exception.$scenario$)
    );

    return query select tap.throws_ok(
        $throws$select add_test(null, null);$throws$,
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Add a test with a null schema and function name. Expect exception.$scenario$)
    );

end;
$$;

COMMIT;
