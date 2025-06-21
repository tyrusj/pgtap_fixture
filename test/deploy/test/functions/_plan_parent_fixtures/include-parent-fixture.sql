-- Deploy dream-db-extension-tests:func-plan-parent-fixtures-include-parent-fixture to pg

BEGIN;

create function unit_test.test_func_plan_parent_fixtures__include_parent_fixture()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
When planning parent fixtures, if the given fixture has a parent fixture, and if that parent fixture is not in
the plan, then the function shall include that fixture in the plan.
$description$;
declare fixture_in_plan integer;
declare fixture_not_in_plan integer;
declare fixture_with_parent_in_plan integer;
declare fixture_with_parent_not_in_plan integer;
begin
    -- Insert a fixture that will already be in the plan
    insert into fixture ("name")
    values ('my_fixture_1')
    returning id into fixture_in_plan
    ;

    -- Insert a fixture that is not in the plan
    insert into fixture ("name")
    values ('my_fixture_2')
    returning id into fixture_not_in_plan
    ;

    -- Insert a fixture whose parent fixture is in the plan
    insert into fixture ("name", "parent_fixture_id")
    values ('my_fixture_3', fixture_in_plan)
    returning id into fixture_with_parent_in_plan
    ;

    -- Insert a fixture whose parent fixture is not in the plan
    insert into fixture ("name", "parent_fixture_id")
    values ('my_fixture_4', fixture_not_in_plan)
    returning id into fixture_with_parent_not_in_plan
    ;

    -- Add a fixture to the plan.
    insert into fixture_plan ("id") values (fixture_in_plan);

    -- Create a copy of the fixture plan table that will not be changed to use as a reference.
    create temp table _fixture_plan_unchanged as table fixture_plan;

    -- Test the scenarios

    perform _plan_parent_fixtures(fixture_with_parent_in_plan);
    return query select tap.results_eq(
        $result$select "id" from fixture_plan$result$,
        $result$select "id" from _fixture_plan_unchanged$result$,
        format(
            E'%s\ntest_scenario: %s', test_description,
			$scenario$1: Plan a fixture whose parent is already in the plan. Expect the plan to remain the same.$scenario$
        )
    );

    perform _plan_parent_fixtures(fixture_with_parent_not_in_plan);
    return query select tap.set_has(
        $set$select "id" from fixture_plan$set$,
        format($has$select "id" from (values (%s)) v(id)$has$, fixture_not_in_plan),
        format(
            E'%s\ntest_scenario: %s', test_description,
			$scenario$2: Plan a fixture whose parent is not already in the plan. Expect the plan to contain the parent fixture.$scenario$
        )
    );

end;
$$;

COMMIT;
