-- Deploy dream-db-extension-tests:functions/_execute_fixture/execute-tests to pg

BEGIN;

create function unit_test.test_func_execute_fixture__execute_tests()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, for each record in the test table whose parent fixture is the given fixture,
if that test is in the plan, then the database shall execute that test with all of its test data.
$test_description$;
declare fixture_id integer;
declare test_id_planned_a integer;
declare test_id_planned_b integer;
declare test_id_unplanned_c integer;
declare test_id_unplanned_d integer;
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

    -- Mock _execute_test to only indicate the tests it was called with.
    alter function _execute_test(testId integer, num integer)
    rename to _execute_test___original;
    create function _execute_test(testId integer, num integer)
    returns setof text
    language plpgsql
    as
    $mock$
    begin
        insert into execution ("executed") values (testId);
    end;
    $mock$;

    -- Create a table to track which tests have been executed
    create temp table execution (executed integer);

    -- Add the fixture
    insert into fixture ("name") values ('my_fixture') returning id into fixture_id;

    -- Add the tests
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_a', fixture_id) returning id into test_id_planned_a;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_b', fixture_id) returning id into test_id_planned_b;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_c', fixture_id) returning id into test_id_unplanned_c;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_d', fixture_id) returning id into test_id_unplanned_d;

    -- Add tests to the plan
    insert into test_plan ("id") values (test_id_planned_a), (test_id_planned_b);

    -- Execute the scenario

    perform _execute_fixture(fixture_id, 1);
    return query select tap.set_eq(
        'select executed from execution',
        format($eq$select v.id from (values (%s), (%s)) v(id)$eq$, test_id_planned_a, test_id_planned_b),
        test_description
    );

end;
$$;

COMMIT;
