-- Deploy dream-db-extension-tests:functions/_execute_fixture/teardown-after to pg

BEGIN;

create function unit_test.test_func_execute_fixture__teardown_after()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture has a parent fixture, and if that fixture has a non-null teardown
statement, then the function shall execute that teardown statement after executing the fixture.
$test_description$;
declare fixture_id integer;
declare child_fixture_id integer;
declare parent_fixture_id integer;
declare fixture_order integer;
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

    -- Create a table to track calls to the parent fixture setup
    create temp table execution ("order" integer, executed text);

    -- Create a sequence that will track what order calls are made in
    create temp sequence execution_order as integer owned by execution."order";

    -- Create the fixtures
    insert into fixture ("name", "teardown") values ('my_fixture_parent', $teardown$insert into execution ("order", "executed") values (nextval('execution_order'), 'parent fixture teardown');$teardown$) returning id into parent_fixture_id;
    insert into fixture ("name", "parent_fixture_id", "shutdown") values ('my_fixture_a', parent_fixture_id, $shutdown$insert into execution ("order", "executed") values (nextval('execution_order'), 'fixture shutdown')$shutdown$) returning id into fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_b', fixture_id) returning id into child_fixture_id;

    -- Add to plan
    insert into fixture_plan ("id") values (fixture_id), (child_fixture_id);

    -- Execute the scenario
    
    perform _execute_fixture(fixture_id, 1);
    select "order" from execution where executed = 'fixture shutdown' into fixture_order;

    return query select tap.results_eq(
        format($results$select executed from execution where execution."order" = %s + 1$results$, fixture_order),
        $eq$select 'parent fixture teardown'$eq$,
        test_description
    );

end;
$$;

COMMIT;
