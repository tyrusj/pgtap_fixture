-- Deploy dream-db-extension-tests:functions/plan-tests-and-fixtures/include-fixtures to pg

BEGIN;

create function unit_test.test_func_plan__include_fixtures()
returns setof text
language plpgsql
as
$$
declare test_description text :=$test_description$
When planning tests and fixtures, for each given fixture, if that fixture is not in the plan, then the
function shall include that fixture in the plan.
$test_description$;
declare fixture_id_already_planned_A integer;
declare fixture_id_already_planned_B integer;
declare fixture_id_already_planned_C integer;
declare fixture_id_already_planned_D integer;
declare fixture_id_unplanned_E integer;
declare fixture_id_unplanned_F integer;
declare fixture_id_unplanned_G integer;
declare fixture_id_unplanned_H integer;
begin
    -- Create the fixtures
    insert into fixture ("name") values ('my_fixture_1') returning id into fixture_id_already_planned_A;
    insert into fixture ("name") values ('my_fixture_2') returning id into fixture_id_already_planned_B;
    insert into fixture ("name") values ('my_fixture_3') returning id into fixture_id_already_planned_C;
    insert into fixture ("name") values ('my_fixture_4') returning id into fixture_id_already_planned_D;
    insert into fixture ("name") values ('my_fixture_5') returning id into fixture_id_unplanned_E;
    insert into fixture ("name") values ('my_fixture_6') returning id into fixture_id_unplanned_F;
    insert into fixture ("name") values ('my_fixture_7') returning id into fixture_id_unplanned_G;
    insert into fixture ("name") values ('my_fixture_8') returning id into fixture_id_unplanned_H;

    -- Add fixtures to the plan
    insert into fixture_plan ("id") values (fixture_id_already_planned_A), (fixture_id_already_planned_B), (fixture_id_already_planned_C), (fixture_id_already_planned_D);

    -- Create a copy of the fixture plan that will remain unchanged to use as a reference
    create temp table fixture_plan_unchanged as table fixture_plan;

    -- Execute the scenarios

    perform _plan_tests_and_fixtures(array[fixture_id_already_planned_A], null);
    return query select tap.results_eq(
        'select id from fixture_plan',
        'select id from fixture_plan_unchanged',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Plan a single fixture that already exists in the plan. Expect the plan to remain unchanged.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(array[fixture_id_already_planned_B, fixture_id_already_planned_C], null);
    return query select tap.results_eq(
        'select id from fixture_plan',
        'select id from fixture_plan_unchanged',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Plan two fixtures that already exist in the plan. Expect the plan to remain unchanged.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(array[fixture_id_unplanned_E], null);
    return query select tap.set_eq(
        'select id from fixture_plan',
        format('select id from fixture_plan_unchanged union select v.id from (values (%s)) as v(id)', fixture_id_unplanned_E),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Plan a single fixture that is not in the plan. Expect the plan to contain the new fixture.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(array[fixture_id_unplanned_F, fixture_id_unplanned_G], null);
    return query select tap.set_eq(
        'select id from fixture_plan',
        format('select id from fixture_plan_unchanged union select v.id from (values (%s), (%s)) as v(id)', fixture_id_unplanned_F, fixture_id_unplanned_G),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: Plan two fixtures that are not in the plan. Expect the plan to contain the two new fixtures.$scenario$)
    );

    delete from fixture_plan;
    insert into fixture_plan select * from fixture_plan_unchanged;
    perform _plan_tests_and_fixtures(array[fixture_id_already_planned_D, fixture_id_unplanned_H], null);
    return query select tap.set_eq(
        'select id from fixture_plan',
        format('select id from fixture_plan_unchanged union select v.id from (values (%s)) as v(id)', fixture_id_unplanned_H),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$5: Plan one fixture that is in the plan and one fixture that is not in the plan. Expect the plan to contain the new fixture.$scenario$)
    );

end;
$$;

COMMIT;
