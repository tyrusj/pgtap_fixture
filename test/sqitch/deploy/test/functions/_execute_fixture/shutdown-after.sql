-- Deploy dream-db-extension-tests:functions/_execute_fixture/shutdown-after to pg

BEGIN;

create function unit_test.test_func_execute_fixture__shutdown_after()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture has a non-null shutdown statement, then the function shall
execute the shutdown statement after executing the last child test or child fixture in the plan.
$test_description$;
declare fixture_id integer;
declare child_fixture_id integer;
declare test_id integer;
declare fixture_order integer;
declare child_fixture_order integer;
declare test_order integer;
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

    -- Add a statement after _execute_fixture that tracks the order of fixture IDs it was called with.
    alter function _execute_fixture(fixtureId integer, num integer)
    rename to _execute_fixture___original;
    create function _execute_fixture(fixtureId integer, num integer)
    returns setof text
    language plpgsql
    as
    $with_order$
    begin
        insert into execution ("order", "executed") values (nextval('execution_order'), 'fixture id ' || fixtureId);
        return query select _execute_fixture___original(fixtureId, num);
    end;
    $with_order$;

    -- Mock _execute_test to only track the order of test IDs it was called with.
    alter function _execute_test(testId integer, num integer)
    rename to _execute_test___original;
    create function _execute_test(testId integer, num integer)
    returns setof text
    language plpgsql
    as
    $mock$
    begin
        insert into execution ("order", "executed") values (nextval('execution_order'), 'test id ' || testId);
    end;
    $mock$;

    -- Create a table to track calls to the parent fixture setup
    create temp table execution ("order" integer, executed text);

    -- Create a sequence that will track what order calls are made in
    create temp sequence execution_order as integer owned by execution."order";

    -- Create the fixtures
    insert into fixture ("name", "shutdown") values ('my_fixture_a', $shutdown$insert into execution ("order", "executed") values (nextval('execution_order'), 'fixture shutdown')$shutdown$) returning id into fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('child_fixture', fixture_id) returning id into child_fixture_id;

    -- Create a test
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_test', fixture_id) returning id into test_id;

    -- Add the child test and child fixture to the plan
    insert into fixture_plan ("id") values (child_fixture_id);
    insert into test_plan ("id") values (test_id);

    -- Execute the scenarios

    perform _execute_fixture(fixture_id, 1);
    select "order" from execution where executed = 'fixture shutdown' into fixture_order;
    select "order" from execution where executed = 'fixture id ' || child_fixture_id into child_fixture_order;
    select "order" from execution where executed = 'test id ' || test_id into test_order;

    return query select tap.ok(
        fixture_order > child_fixture_order,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Fixture shutdown executed after child fixture.$scenario$)
    );

    return query select tap.ok(
        fixture_order > test_order,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Fixture shutdown executed after child test.$scenario$)
    );

end;
$$;

COMMIT;
