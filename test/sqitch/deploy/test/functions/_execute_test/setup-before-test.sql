-- Deploy dream-db-extension-tests:functions/_execute_test/setup-before-test to pg

BEGIN;

create function unit_test.test_func_execute_test__setup_before_test()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, for each record in the test data table that corresponds with the
given test, if the test has a parent fixture, and if that fixture has a setup statement, then the
function shall execute that setup statement before executing the test with data.
$test_description$;
declare test_id integer;
declare fixture_id integer;
declare params1_order integer;
declare params2_order integer;
begin

    -- Stub pg_tap functions that can interfere with tests.
    alter function pgtap__cleanup()
    rename to pgtap__cleanup___original;
    create function pgtap__cleanup()
    returns boolean
    language plpgsql
    as
    $stub$
    begin
        return null;
    end;
    $stub$;

    alter function pgtap_no_plan()
    rename to pgtap_no_plan___original;
    create function pgtap_no_plan()
    returns setof boolean
    language plpgsql
    as
    $stub$
    begin
        
    end;
    $stub$;

    alter function pgtap__restart_numb_seq()
    rename to  pgtap__restart_numb_seq___original;
    create function pgtap__restart_numb_seq()
    returns void
    language plpgsql
    as
    $stub$
    begin

    end;
    $stub$;

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

    -- Create a table where the description that a test is executed with will be stored.
    create temp table execution("order" integer, executed text);

    -- Create a sequence that will track what order the setup and test function are executed in.
    create temp sequence execution_order as integer owned by execution."order";

    -- Create a test function
    create function pg_temp.my_test_function_a(parameters jsonb, testDescription text)
    returns setof text
    language plpgsql
    as
    $test$
    begin
        insert into execution ("order", "executed") values (nextval('execution_order'), 'test function with ' || (parameters->>0)::text);
    end;
    $test$
    ;

    -- Create a fixture
    insert into fixture ("name", "setup") values ('my_fixture', $setup$insert into execution ("order", "executed") values (nextval('execution_order'), 'fixture setup');$setup$) returning id into fixture_id;

    -- Create a test record
    insert into test ("schema", "function", "parent_fixture_id") values ('pg_temp', 'my_test_function_a', fixture_id) returning id into test_id;

    -- Create test data
    insert into test_data ("test_id", "parameters") values (test_id, $params$select '["params1"]'$params$);
    insert into test_data ("test_id", "parameters") values (test_id, $params$select '["params2"]'$params$);

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    -- Execute the scenarios
    perform _execute_test(test_id, 1);
    select "order" from execution where executed = 'test function with params1' into params1_order;
    select "order" from execution where executed = 'test function with params2' into params2_order;

    return query select tap.results_eq(
        format($results$select executed from execution where execution."order" = %s - 1;$results$, params1_order),
        $expect$select v.executed from (values ('fixture setup')) v(executed)$expect$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Execute fixture setup before test with data params1.$scenario$)
    );

    return query select tap.results_eq(
        format($results$select executed from execution where execution."order" = %s - 1;$results$, params2_order),
        $expect$select v.executed from (values ('fixture setup')) v(executed)$expect$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Execute fixture setup before test with data params2.$scenario$)
    );

end;
$$;

COMMIT;
