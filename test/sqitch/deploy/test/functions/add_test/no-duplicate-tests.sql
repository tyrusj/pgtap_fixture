-- Deploy dream-db-extension-tests:functions/add_test/no-duplicate-tests to pg

BEGIN;

create function unit_test.test_func_add_test__no_duplicate_tests()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When adding a test, if a record already exists in the test table whose test ID corresponds with the
given schema and function, then the database shall throw an exception.
$test_description$;
begin

    -- Create a test
    insert into test ("schema", "function") values ('my_schema', 'my_function');

    return query select tap.throws_ok(
        $throws$select add_test('my_schema', 'my_function');$throws$,
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Add a test with the same schema and function name as an existing test. Expect exception.$scenario$)
    );

    return query select tap.lives_ok(
        $lives$select add_test('my_schema', 'my_function_2');$lives$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Add a test with the same schema but a different function name from an existing test. Expect no exception.$scenario$)
    );

    return query select tap.lives_ok(
        $lives$select add_test('my_schema_2', 'my_function');$lives$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Add a test with the same function name but a different schema name from an existing test. Expect no exception.$scenario$)
    );

    return query select tap.lives_ok(
        $lives$select add_test('my_schema_3', 'my_function_3');$lives$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: Add a test with a unique schema and function name. Expect no exception.$scenario$)
    );

end;
$$;

COMMIT;
