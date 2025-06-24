-- Deploy dream-db-extension-tests:functions/plan-tests-and-fixtures/include-test-parents to pg

BEGIN;

create function unit_test.test_func_plan__include_test_parents()
returns setof text
language plpgsql
as
$$
declare test_description text :=$test_description$
When planning tests and fixtures, for each given test, if that test has a parent fixture, and if that
parent fixture is not in the plan, then the function shall include that fixture in the plan.
$test_description$;
declare parent_fixture_id_A integer;
declare parent_fixture_id_B integer;
declare parent_fixture_id_C integer;
declare parent_fixture_id_D integer;
declare parent_fixture_id_already_planned_E integer;
declare parent_fixture_id_already_planned_F integer;
declare parent_fixture_id_already_planned_G integer;
declare parent_fixture_id_already_planned_H integer;
declare test_without_parent_id_1 integer;
declare test_without_parent_id_2 integer;
declare test_without_parent_id_3 integer;
declare test_without_parent_id_4 integer;
declare test_with_parent_id_A integer;
declare test_with_parent_id_B integer;
declare test_with_parent_id_C integer;
declare test_with_parent_id_D integer;
declare test_with_parent_id_already_planned_E integer;
declare test_with_parent_id_already_planned_F integer;
declare test_with_parent_id_already_planned_G integer;
declare test_with_parent_id_already_planned_H integer;
begin

    -- Create the fixtures
    insert into fixture ("name") values ('my_fixture_1') returning id into parent_fixture_id_A;
    insert into fixture ("name") values ('my_fixture_2') returning id into parent_fixture_id_B;
    insert into fixture ("name") values ('my_fixture_3') returning id into parent_fixture_id_C;
    insert into fixture ("name") values ('my_fixture_4') returning id into parent_fixture_id_D;
    insert into fixture ("name") values ('my_fixture_5') returning id into parent_fixture_id_already_planned_E;
    insert into fixture ("name") values ('my_fixture_6') returning id into parent_fixture_id_already_planned_F;
    insert into fixture ("name") values ('my_fixture_7') returning id into parent_fixture_id_already_planned_G;
    insert into fixture ("name") values ('my_fixture_8') returning id into parent_fixture_id_already_planned_H;

    -- Create the tests
    insert into test ("schema", "function") values ('my_schema', 'my_function_1') returning id into test_without_parent_id_1;
    insert into test ("schema", "function") values ('my_schema', 'my_function_2') returning id into test_without_parent_id_2;
    insert into test ("schema", "function") values ('my_schema', 'my_function_3') returning id into test_without_parent_id_3;
    insert into test ("schema", "function") values ('my_schema', 'my_function_4') returning id into test_without_parent_id_4;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_5', parent_fixture_id_A) returning id into test_with_parent_id_A;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_6', parent_fixture_id_B) returning id into test_with_parent_id_B;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_7', parent_fixture_id_C) returning id into test_with_parent_id_C;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_8', parent_fixture_id_D) returning id into test_with_parent_id_D;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_9', parent_fixture_id_already_planned_E) returning id into test_with_parent_id_already_planned_E;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_10', parent_fixture_id_already_planned_F) returning id into test_with_parent_id_already_planned_F;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_11', parent_fixture_id_already_planned_G) returning id into test_with_parent_id_already_planned_G;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_12', parent_fixture_id_already_planned_H) returning id into test_with_parent_id_already_planned_H;

    -- Add fixtures to the plan that should already be planned
    insert into fixture_plan ("id") values (parent_fixture_id_already_planned_E), (parent_fixture_id_already_planned_F), (parent_fixture_id_already_planned_G), (parent_fixture_id_already_planned_H);

    -- Create a copy of the fixture plan that will remain unchanged to use as a reference
    create temp table fixture_plan_unchanged as table fixture_plan;

    perform _plan_tests_and_fixtures(null, array[test_without_parent_id_1]);
    return query select tap.results_eq(
        'select id from fixture_plan',
        'select id from fixture_plan_unchanged',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Plan one test with no parent fixture. Expect the fixture plan to remain the same.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(null, array[test_with_parent_id_A]);
    return query select tap.set_has(
        'select id from fixture_plan',
        format('select id from fixture_plan_unchanged union select v.id from (values (%s)) as v(id)', parent_fixture_id_A),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: plan one test with a parent fixture. Expect the fixture plan to contain the parent fixture.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(null, array[test_without_parent_id_2, test_without_parent_id_3]);
    return query select tap.results_eq(
        'select id from fixture_plan',
        'select id from fixture_plan_unchanged',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Plan two tests with no parent fixture. Expect the fixture plan to remain the same.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(null, array[test_with_parent_id_B, test_with_parent_id_C]);
    return query select tap.set_has(
        'select id from fixture_plan',
        format('select id from fixture_plan_unchanged union select v.id from (values (%s), (%s)) as v(id)', parent_fixture_id_B, parent_fixture_id_C),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: Plan two tests with parent fixtures. Expect the fixture plan to contain the two parent fixtures.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(null, array[test_without_parent_id_4, test_with_parent_id_D]);
    return query select tap.set_has(
        'select id from fixture_plan',
        format('select id from fixture_plan_unchanged union select v.id from (values (%s)) as v(id)', parent_fixture_id_D),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$5: Plan two tests, one with a parent fixture, one without. Expect the fixture plan to contain the parent fixture.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(null, array[test_with_parent_id_already_planned_E]);
    return query select tap.results_eq(
        'select id from fixture_plan',
        'select id from fixture_plan_unchanged',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$6: Plan one test with a parent fixture that is already in the plan. Expect the fixture plan to remain the same.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(null, array[test_with_parent_id_already_planned_F, test_with_parent_id_already_planned_G]);
    return query select tap.results_eq(
        'select id from fixture_plan',
        'select id from fixture_plan_unchanged',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$7: Plan two tests with a parent fixture that are already in the plan. Expect the fixture plan to remain the same.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(null, array[test_with_parent_id_already_planned_H, test_with_parent_id_A]);
    return query select tap.set_has(
        'select id from fixture_plan',
        format('select id from fixture_plan_unchanged union select v.id from (values (%s)) as v(id)', parent_fixture_id_A),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$8: Plan two tests with a parent fixture, one of which is already in the plan. Expect the plan to contain the fixture that was not already in the plan.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(null, array[]::integer[]);
    return query select tap.results_eq(
        'select id from fixture_plan',
        'select id from fixture_plan_unchanged',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$9: Plan an empty array of tests. Expect the plan to remain the same.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(null, null);
    return query select tap.results_eq(
        'select id from fixture_plan',
        'select id from fixture_plan_unchanged',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$10: Plan a null array of tests. Expect the plan to remain the same.$scenario$)
    );
    
end;
$$;

COMMIT;
