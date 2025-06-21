-- Deploy dream-db-extension-tests:functions/plan-tests-and-fixtures/include-tests to pg

BEGIN;

create function unit_test.test_func_plan__include_tests()
returns setof text
language plpgsql
as
$$
declare test_description text :=$test_description$
When planning tests and fixtures, for each given test, if that test is not in the plan, then the function
shall include that test in the plan.
$test_description$;
declare test_id_already_planned_A integer;
declare test_id_already_planned_B integer;
declare test_id_already_planned_C integer;
declare test_id_already_planned_D integer;
declare test_id_unplanned_E integer;
declare test_id_unplanned_F integer;
declare test_id_unplanned_G integer;
declare test_id_unplanned_H integer;
begin
    -- Create the tests
    insert into test ("schema", "function") values ('my_schema', 'my_function_1') returning id into test_id_already_planned_A;
    insert into test ("schema", "function") values ('my_schema', 'my_function_2') returning id into test_id_already_planned_B;
    insert into test ("schema", "function") values ('my_schema', 'my_function_3') returning id into test_id_already_planned_C;
    insert into test ("schema", "function") values ('my_schema', 'my_function_4') returning id into test_id_already_planned_D;
    insert into test ("schema", "function") values ('my_schema', 'my_function_5') returning id into test_id_unplanned_E;
    insert into test ("schema", "function") values ('my_schema', 'my_function_6') returning id into test_id_unplanned_F;
    insert into test ("schema", "function") values ('my_schema', 'my_function_7') returning id into test_id_unplanned_G;
    insert into test ("schema", "function") values ('my_schema', 'my_function_8') returning id into test_id_unplanned_H;

    -- Add tests to the plan
    insert into test_plan ("id") values (test_id_already_planned_A), (test_id_already_planned_B), (test_id_already_planned_C), (test_id_already_planned_D);

    -- Create a copy of the test plan that will remain unchange to use as a reference
    create temp table test_plan_unchanged as table test_plan;

    -- Execute the scenarios

    perform _plan_tests_and_fixtures(null, array[test_id_already_planned_A]);
    return query select tap.results_eq(
        'select id from test_plan',
        'select id from test_plan_unchanged',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Plan a single test that already exists in the plan. Expect the plan to remain unchanged.$scenario$)
    );

    delete from test_plan;
    insert into test_plan select * from test_plan_unchanged;
    perform _plan_tests_and_fixtures(null, array[test_id_already_planned_B, test_id_already_planned_C]);
    return query select tap.results_eq(
        'select id from test_plan',
        'select id from test_plan_unchanged',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Plan two tests that already exist in the plan. Expect the plan to remain unchanged.$scenario$)
    );

    delete from test_plan;
    insert into test_plan select * from test_plan_unchanged;
    perform _plan_tests_and_fixtures(null, array[test_id_unplanned_E]);
    return query select tap.set_eq(
        'select id from test_plan',
        format('select id from test_plan_unchanged union select v.id from (values (%s)) as v(id)', test_id_unplanned_E),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Plan a single test that is not in the plan. Expect the plan to contain the new test.$scenario$)
    );

    delete from test_plan;
    insert into test_plan select * from test_plan_unchanged;
    perform _plan_tests_and_fixtures(null, array[test_id_unplanned_F, test_id_unplanned_G]);
    return query select tap.set_eq(
        'select id from test_plan',
        format('select id from test_plan_unchanged union select v.id from (values (%s), (%s)) as v(id)', test_id_unplanned_F, test_id_unplanned_G),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: Plan two tests that are not in the plan. Expect the plan to contain the two new tests.$scenario$)
    );

    delete from test_plan;
    insert into test_plan select * from test_plan_unchanged;
    perform _plan_tests_and_fixtures(null, array[test_id_already_planned_D, test_id_unplanned_H]);
    return query select tap.set_eq(
        'select id from test_plan',
        format('select id from test_plan_unchanged union select v.id from (values (%s)) as v(id)', test_id_unplanned_H),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$5: Plan one test that is in the plan and one test that is not in the plan. Expect the plan to contain the new test.$scenario$)
    );

end;
$$;

COMMIT;
