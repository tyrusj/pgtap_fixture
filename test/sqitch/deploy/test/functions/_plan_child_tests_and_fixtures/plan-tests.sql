-- Deploy dream-db-extension-tests:functions/plan-child-tests-and-fixtures/plan-tests to pg

BEGIN;

create function unit_test.test_func_plan_children__plan_tests()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When planning child tests and fixtures, for the given fixture, for each test whose parent fixture is that
fixture, if that test is not in the plan, then the function shall include that test in the plan.
$test_description$;
declare test_id_already_planned integer;
declare test_id_A integer;
declare test_id_B integer;
declare fixture_id_with_no_tests integer;
declare fixture_id_with_tests integer;
declare fixture_id_with_tests_already_planned integer;
begin
    -- Create fixtures
    insert into fixture ("name") values ('my_fixture_1') returning id into fixture_id_with_no_tests;
    insert into fixture ("name") values ('my_fixture_2') returning id into fixture_id_with_tests;
    insert into fixture ("name") values ('my_fixture_3') returning id into fixture_id_with_tests_already_planned;

    -- Create tests
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_test_1', fixture_id_with_tests_already_planned) returning id into test_id_already_planned;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_test_2', fixture_id_with_tests) returning id into test_id_A;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_test_3', fixture_id_with_tests) returning id into test_id_B;

    -- Add tests that are already planned
    insert into test_plan ("id") values (test_id_already_planned);

    -- Create a copy of the test plan table that will remain unchanged to use as a reference.
    create temp table _test_plan_unchanged as table test_plan;

    -- Execute the scenarios

    
    perform _plan_child_tests_and_fixtures(fixture_id_with_tests_already_planned);
    return query select tap.results_eq(
        'select id from _test_plan_unchanged',
        'select id from test_plan',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Plan a fixture with a child test that is already planned. Expect the test plan to remain the same.$scenario$)
    );
    
    -- Reset the test plan
    delete from test_plan;
    insert into test_plan select * from _test_plan_unchanged;

    perform _plan_child_tests_and_fixtures(fixture_id_with_no_tests);
    return query select tap.results_eq(
        'select id from _test_plan_unchanged',
        'select id from test_plan',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Plan a fixture that has no child tests. Expect the test plan to remain the same.$scenario$)
    );

    -- Reset the test plan
    delete from test_plan;
    insert into test_plan select * from _test_plan_unchanged;

    perform _plan_child_tests_and_fixtures(fixture_id_with_tests);
    return query select tap.set_eq(
        'select id from test_plan',
        format('select id from _test_plan_unchanged union select id from (values (%s), (%s)) as v(id)', test_id_A, test_id_B),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Plan a fixture that has child tests. Expect the child tests to be added to the test plan.$scenario$)
    );

end;
$$;

COMMIT;
