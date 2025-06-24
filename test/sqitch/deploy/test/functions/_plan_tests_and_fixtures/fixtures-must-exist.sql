-- Deploy dream-db-extension-tests:functions/plan-tests-and-fixtures/fixtures-must-exist to pg

BEGIN;

create function unit_test.test_func_plan__fixtures_must_exist()
returns setof text
language plpgsql
as
$$
declare test_description text :=$test_description$
When planning tests and fixtures, for each given fixture, if that fixture does not exist, then the function
shall throw an exception.
$test_description$;
declare one_fixture_exists integer[];
declare one_fixture_not_exists integer[];
declare one_fixture_null integer[];
declare two_fixtures_exist integer[];
declare two_fixtures_not_exists integer[];
declare two_fixtures_one_not_exists integer[];
declare two_fixtures_one_null integer[];
declare fixture_exists_A integer;
declare fixture_exists_B integer;
declare fixture_not_exists_C integer;
declare fixture_not_exists_D integer;
begin
    -- Create tests
    insert into fixture ("name") values ('my_fixture_1') returning id into fixture_exists_A;
    insert into fixture ("name") values ('my_fixture_2') returning id into fixture_exists_B;
    insert into fixture ("name") values ('my_fixture_3') returning id into fixture_not_exists_C;
    insert into fixture ("name") values ('my_fixture_4') returning id into fixture_not_exists_D;

    -- Delete fixtures to guarantee that they don't exist
    delete from fixture where id in (fixture_not_exists_C, fixture_not_exists_D);

    -- Populate the arrays for testing
    one_fixture_exists := array[fixture_exists_A];
    one_fixture_not_exists := array[fixture_not_exists_C];
    one_fixture_null := array[null];
    two_fixtures_exist := array[fixture_exists_A, fixture_exists_B];
    two_fixtures_not_exists := array[fixture_not_exists_C, fixture_not_exists_D];
    two_fixtures_one_not_exists := array[fixture_exists_B, fixture_not_exists_D];
    two_fixtures_one_null := array[fixture_exists_A, null];

    -- Create a temp table to use to pass the arrays to the tests, since arrays can't be passed to format strings.
    create temp table fixture_array (arr integer[]);

    -- Execute scenarios

    return query select tap.lives_ok(
        'select _plan_tests_and_fixtures(null, null)',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Plan a null array of fixtures. Expect no exception.$scenario$)
    );

    return query select tap.lives_ok(
        'select _plan_tests_and_fixtures(array[]::integer[], null)',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Plan an empty array of fixtures. Expect no exception.$scenario$)
    );

    delete from fixture_array;
    insert into fixture_array values (one_fixture_exists);
    return query select tap.lives_ok(
        'select _plan_tests_and_fixtures(arr, null) from fixture_array',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Plan an array of one fixture that exists. Expect no exception.$scenario$)
    );

    delete from fixture_array;
    insert into fixture_array values (one_fixture_not_exists);
    return query select tap.throws_ok(
        'select _plan_tests_and_fixtures(arr, null) from fixture_array',
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: Plan an array of one fixture that does not exist. Expect exception.$scenario$)
    );

    delete from fixture_array;
    insert into fixture_array values (one_fixture_null);
    return query select tap.throws_ok(
        'select _plan_tests_and_fixtures(arr, null) from fixture_array',
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$5: Plan an array of one fixture that is null. Expect exception.$scenario$)
    );

    delete from fixture_array;
    insert into fixture_array values (two_fixtures_exist);
    return query select tap.lives_ok(
        'select _plan_tests_and_fixtures(arr, null) from fixture_array',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$6: Plan an array of two fixtures that exist. Expect no exception.$scenario$)
    );

    delete from fixture_array;
    insert into fixture_array values (two_fixtures_not_exists);
    return query select tap.throws_ok(
        'select _plan_tests_and_fixtures(arr, null) from fixture_array',
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$7: Plan an array of two fixtures that don't exist. Expect exception.$scenario$)
    );

    delete from fixture_array;
    insert into fixture_array values (two_fixtures_one_not_exists);
    return query select tap.throws_ok(
        'select _plan_tests_and_fixtures(arr, null) from fixture_array',
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$8: Plan an array of two fixtures where one exists and the other does not exist. Expect exception.$scenario$)
    );

    delete from fixture_array;
    insert into fixture_array values (two_fixtures_one_null);
    return query select tap.throws_ok(
        'select _plan_tests_and_fixtures(arr, null) from fixture_array',
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$9: Plan an array of two fixtures where one exists and the other is null. Expect exception.$scenario$)
    );

end;
$$;

COMMIT;
