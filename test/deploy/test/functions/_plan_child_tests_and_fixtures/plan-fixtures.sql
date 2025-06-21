-- Deploy dream-db-extension-tests:functions/plan-child-tests-and-fixtures/plan-fixtures to pg

BEGIN;

create function unit_test.test_func_plan_children__plan_fixtures()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When planning child tests and fixtures, for the given fixture, for each (child) fixture whose parent fixture
is that fixture, the function shall include that (child) fixture in the plan.
$test_description$;
declare fixture_id_already_planned integer;
declare fixture_id_A integer;
declare fixture_id_B integer;
declare fixture_id_with_no_child_fixtures integer;
declare fixture_id_with_child_fixtures integer;
declare fixture_id_with_child_fixtures_already_planned integer;
begin
    -- Create fixtures
    insert into fixture ("name") values ('my_fixture_4') returning id into fixture_id_with_no_child_fixtures;
    insert into fixture ("name") values ('my_fixture_5') returning id into fixture_id_with_child_fixtures;
    insert into fixture ("name") values ('my_fixture_6') returning id into fixture_id_with_child_fixtures_already_planned;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_1', fixture_id_with_child_fixtures_already_planned) returning id into fixture_id_already_planned;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_2', fixture_id_with_child_fixtures) returning id into fixture_id_A;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_3', fixture_id_with_child_fixtures) returning id into fixture_id_B;

    -- Add fixtures that are already planned
    insert into fixture_plan ("id") values (fixture_id_already_planned);

    -- Create a copy of the fixture plan that will remain unchanged to use as a reference
    create temp table _fixture_plan_unchanged as table fixture_plan;

    -- Execute the scenarios
    
    perform _plan_child_tests_and_fixtures(fixture_id_with_child_fixtures_already_planned);
    return query select tap.results_eq(
        'select id from _fixture_plan_unchanged',
        'select id from fixture_plan',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Plan a fixture with a child fixture that is already planned. Expect the fixture plan to remain the same.$scenario$)
    );

    -- Reset the fixture plan
    delete from fixture_plan;
    insert into fixture_plan select * from _fixture_plan_unchanged;

    perform _plan_child_tests_and_fixtures(fixture_id_with_no_child_fixtures);
    return query select tap.results_eq(
        'select id from _fixture_plan_unchanged',
        'select id from fixture_plan',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Plan a fixture that has no child fixtures. Expect the fixture plan to remain the same.$scenario$)
    );

    -- Reset the fixture plan
    delete from fixture_plan;
    insert into fixture_plan select * from _fixture_plan_unchanged;
    
    perform _plan_child_tests_and_fixtures(fixture_id_with_child_fixtures);
    return query select tap.set_eq(
        'select id from fixture_plan',
        format('select id from _fixture_plan_unchanged union select id from (values (%s), (%s)) as v(id)', fixture_id_A, fixture_id_B),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Plan a fixture that has child fixtures. Expect the child fixtures to be added to the fixture plan.$scenario$)
    );

end;
$$;

COMMIT;
