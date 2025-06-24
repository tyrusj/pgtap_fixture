-- Deploy dream-db-extension-tests:functions/_execute_fixture/rollback-changes to pg

BEGIN;

create function unit_test.test_func_execute_fixture__rollback_changes()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, after executing a fixture, the function shall rollback changes made by the
parent fixture setup, the fixture startup, the child tests, the child fixtures, the fixture shutdown,
and the parent fixture teardown.
$test_description$;
declare fixture_id integer;
declare parent_fixture_id integer;
declare child_fixture_id integer;
declare test_id integer;
begin

    -- Change _execute_fixture to also make an arbitrary change that should be rolled back.
    alter function _execute_fixture(fixtureId integer, num integer)
    rename to _execute_fixture___original;
    create function _execute_fixture(fixtureId integer, num integer)
    returns setof text
    language plpgsql
    as
    $with_arbitrary_change$
    begin
        return query select _execute_fixture___original(fixtureId, num);
        insert into arbitrary_changes ("change") values ('change from fixture id ' || fixtureId);
    end;
    $with_arbitrary_change$;

    -- Mock _execute_test to make an arbitrary change that should be rolled back.
    alter function _execute_test(testId integer, num integer)
    rename to _execute_test___original;
    create function _execute_test(testId integer, num integer)
    returns setof text
    language plpgsql
    as
    $mock$
    begin
        insert into arbitrary_changes ("change") values ('change from test id ' || testId);
    end;
    $mock$;

    -- Create a table where arbitrary changes are made that should be rolled back.
    create temp table arbitrary_changes (change text);

    -- Add the fixtures
    insert into fixture ("name", "setup", "teardown")
    values (
        'parent_fixture',
        $setup$insert into arbitrary_changes ("change") values ('change from parent setup');$setup$,
        $teardown$insert into arbitrary_changes ("change") values ('change from parent teardown');$teardown$
    )
    returning id into parent_fixture_id;

    insert into fixture ("name", "parent_fixture_id", "startup", "shutdown")
    values (
        'my_fixture',
        parent_fixture_id,
        $startup$insert into arbitrary_changes ("change") values ('change from fixture startup');$startup$,
        $shutdown$insert into arbitrary_changes ("change") values ('change from fixture shutdown');$shutdown$
    )
    returning id into fixture_id;

    insert into fixture ("name", "parent_fixture_id") values ('child_fixture', fixture_id) returning id into child_fixture_id;

    -- Add the tests
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function', fixture_id) returning id into test_id;

    -- Add tests and fixtures to the plan
    insert into fixture_plan ("id") values (child_fixture_id);
    insert into test_plan ("id") values (test_id);

    -- Execute the scenario

    -- The only non-rollbacked change is the one added by the first call to _execute_fixture.
    perform _execute_fixture(fixture_id, 1);
    return query select tap.results_eq(
        'select change from arbitrary_changes',
        format('select v.change from (values (%L)) v(change)', 'change from fixture id ' || fixture_id),
        test_description
    );

end;
$$;

COMMIT;
