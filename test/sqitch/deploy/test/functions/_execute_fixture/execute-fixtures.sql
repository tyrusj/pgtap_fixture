-- Deploy dream-db-extension-tests:functions/_execute_fixture/execute-fixtures to pg

BEGIN;

create function unit_test.test_func_execute_fixture__execute_fixtures()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, for each record in the fixture table whose parent fixture is the given fixture,
if that fixture is in the plan, then the database shall execute that fixture.
$test_description$;
declare fixture_id integer;
declare fixture_id_planned_a integer;
declare fixture_id_planned_b integer;
declare fixture_id_unplanned_c integer;
declare fixture_id_unplanned_d integer;
begin

    -- Stub the rollback function, so that changes aren't automatically rolled back.
    alter function _function_rollback()
    rename to _function_rollback___original;
    create function _function_rollback()
    returns void
    language plpgsql
    as
    $stub$
    begin
        
    end;
    $stub$;

    -- Mock _execute_fixture to also indicate the fixtures it was called with.
    alter function _execute_fixture(fixtureId integer, num integer)
    rename to _execute_fixture___original;
    create function _execute_fixture(fixtureId integer, num integer)
    returns setof text
    language plpgsql
    as
    $mock$
    begin
        return query select _execute_fixture___original(fixtureId, num);
        insert into execution ("executed") values (fixtureId);
    end;
    $mock$;

    -- Create a table to track which fixtures have been executed
    create temp table execution (executed integer);

    -- Add the fixtures
    insert into fixture ("name") values ('my_fixture') returning id into fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_a', fixture_id) returning id into fixture_id_planned_a;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_b', fixture_id) returning id into fixture_id_planned_b;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_c', fixture_id) returning id into fixture_id_unplanned_c;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_d', fixture_id) returning id into fixture_id_unplanned_d;

    -- Add fixtures to the plan
    insert into fixture_plan ("id") values (fixture_id_planned_a), (fixture_id_planned_b);

    -- Execute the scenario

    perform _execute_fixture(fixture_id, 1);
    return query select tap.set_eq(
        'select executed from execution',
        format($eq$select v.id from (values (%s), (%s), (%s)) v(id)$eq$, fixture_id_planned_a, fixture_id_planned_b, fixture_id),
        test_description
    );

end;
$$;

COMMIT;
