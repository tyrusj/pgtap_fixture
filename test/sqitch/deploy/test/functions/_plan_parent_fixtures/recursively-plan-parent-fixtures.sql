-- Deploy dream-db-extension-tests:func-plan-parent-fixture-recursively-plan-parent-fixtures to pg

BEGIN;

create function unit_test.test_func_plan_parent_fixtures__recursively_plan_fixtures()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
When planning fixtures, if the given fixture has a parent fixture, then the function shall recursively
include parent fixtures and parent parent fixtures in the plan.
$description$;
declare root_fixture_id integer;
declare child_fixture_id integer;
declare child_child_fixture_id integer;
declare child_child_child_fixture_id integer;
begin

    -- Insert a fixture, and several generations of child fixtures.
    insert into fixture ("name")
    values ('my_fixture_A')
    returning id into root_fixture_id
    ;

    insert into fixture ("name", "parent_fixture_id")
    values ('my_fixture_B', root_fixture_id)
    returning id into child_fixture_id
    ;

    insert into fixture ("name", "parent_fixture_id")
    values ('my_fixture_C', child_fixture_id)
    returning id into child_child_fixture_id
    ;

    insert into fixture ("name", "parent_fixture_id")
    values ('my_fixture_D', child_child_fixture_id)
    returning id into child_child_child_fixture_id
    ;

    -- Plan the parent of the last descendant fixture
    perform _plan_parent_fixtures(child_child_child_fixture_id);

    -- Assert that all parent fixtures of the last descendant fixture are included in the plan.
    return query select tap.set_has(
        $set$select "id" from fixture_plan$set$,
        format($has$select "id" from (values (%s), (%s), (%s)) v(id)$has$, child_child_fixture_id, child_fixture_id, root_fixture_id),
        test_description
    );

end;
$$;

COMMIT;
