-- Deploy dream-db-extension-tests:functions/plan-tests-and-fixtures/tests-must-exist to pg

BEGIN;

create function unit_test.test_func_plan__tests_must_exist()
returns setof text
language plpgsql
as
$$
declare test_description text :=$test_description$
When planning tests and fixtures, for each given test, if that test does not exist, then the function shall
throw an exception.
$test_description$;
declare one_test_exists integer[];
declare one_test_not_exists integer[];
declare one_test_null integer[];
declare two_tests_exist integer[];
declare two_tests_not_exists integer[];
declare two_tests_one_not_exists integer[];
declare two_tests_one_null integer[];
declare test_exists_A integer;
declare test_exists_B integer;
declare test_not_exists_C integer;
declare test_not_exists_D integer;
begin
    -- Create tests
    insert into test ("schema", "function") values ('my_schema', 'my_function_1') returning id into test_exists_A;
    insert into test ("schema", "function") values ('my_schema', 'my_function_2') returning id into test_exists_B;
    insert into test ("schema", "function") values ('my_schema', 'my_function_3') returning id into test_not_exists_C;
    insert into test ("schema", "function") values ('my_schema', 'my_function_4') returning id into test_not_exists_D;

    -- Delete tests to guarantee that they don't exist
    delete from test where id in (test_not_exists_C, test_not_exists_D);

    -- Populate the arrays for testing
    one_test_exists := array[test_exists_A];
    one_test_not_exists := array[test_not_exists_C];
    one_test_null := array[null];
    two_tests_exist := array[test_exists_A, test_exists_B];
    two_tests_not_exists := array[test_not_exists_C, test_not_exists_D];
    two_tests_one_not_exists := array[test_exists_B, test_not_exists_D];
    two_tests_one_null := array[test_exists_A, null];

    -- Create a temp table to use to pass the arrays to the tests, since arrays can't be passed to format strings.
    create temp table test_array (arr integer[]);

    -- Execute scenarios

    return query select tap.lives_ok(
        'select _plan_tests_and_fixtures(null, null)',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Plan a null array of tests. Expect no exception.$scenario$)
    );

    return query select tap.lives_ok(
        'select _plan_tests_and_fixtures(null, array[]::integer[])',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Plan an empty array of tests. Expect no exception.$scenario$)
    );

    delete from test_array;
    insert into test_array values (one_test_exists);
    return query select tap.lives_ok(
        'select _plan_tests_and_fixtures(null, arr) from test_array',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Plan an array of one test that exists. Expect no exception.$scenario$)
    );

    delete from test_array;
    insert into test_array values (one_test_not_exists);
    return query select tap.throws_ok(
        'select _plan_tests_and_fixtures(null, arr) from test_array',
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: Plan an array of one test that does not exist. Expect exception.$scenario$)
    );

    delete from test_array;
    insert into test_array values (one_test_null);
    return query select tap.throws_ok(
        'select _plan_tests_and_fixtures(null, arr) from test_array',
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$5: Plan an array of one test that is null. Expect exception.$scenario$)
    );

    delete from test_array;
    insert into test_array values (two_tests_exist);
    return query select tap.lives_ok(
        'select _plan_tests_and_fixtures(null, arr) from test_array',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$6: Plan an array of two tests that exist. Expect no exception.$scenario$)
    );

    delete from test_array;
    insert into test_array values (two_tests_not_exists);
    return query select tap.throws_ok(
        'select _plan_tests_and_fixtures(null, arr) from test_array',
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$7: Plan an array of two tests that don't exist. Expect exception.$scenario$)
    );

    delete from test_array;
    insert into test_array values (two_tests_one_not_exists);
    return query select tap.throws_ok(
        'select _plan_tests_and_fixtures(null, arr) from test_array',
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$8: Plan an array of two tests where one exists and the other does not exist. Expect exception.$scenario$)
    );

    delete from test_array;
    insert into test_array values (two_tests_one_null);
    return query select tap.throws_ok(
        'select _plan_tests_and_fixtures(null, arr) from test_array',
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$9: Plan an array of two tests where one exists and the other is null. Expect exception.$scenario$)
    );

end;
$$;

COMMIT;
