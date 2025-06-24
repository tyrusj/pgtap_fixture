-- Deploy dream-db-extension-tests:functions/_execute_test/execute-with-no-arguments to pg

BEGIN;

create function unit_test.test_func_execute_test__execute_with_no_arguments()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if a test function has no arguments, then the database shall execute
the test function once regardless of whether there are test data records associated with it.
$test_description$;
declare test_id integer;
begin

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

    alter function pgtap__set(text, integer)
    rename to pgtap__set___original;
    create function pgtap__set(text, integer)
    returns integer
    language plpgsql
    as
    $stub$
    begin
        return null;
    end;
    $stub$;
    
    alter function pgtap__get(text)
    rename to pgtap__get___original;
    create function pgtap__get(text)
    returns integer
    language plpgsql
    as
    $stub$
    begin
        return null;
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

    -- Create a table that will store whether the test function was executed.
    create temp table executed_status(executed boolean);

    -- Create a test function
    create function pg_temp.my_test_function_a()
    returns setof text
    language plpgsql
    as
    $test$
    begin
        insert into executed_status ("executed") values (true);
    end;
    $test$
    ;

    -- Create a test record
    insert into test ("schema", "function") values ('pg_temp', 'my_test_function_a') returning id into test_id;

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    -- Execute the scenarios

    delete from executed_status;
    insert into test_data ("test_id", "parameters") values (test_id, $params$select '["params1"]'$params$);
    insert into test_data ("test_id", "parameters") values (test_id, $params$select '["params2"]'$params$);
    perform _execute_test(test_id, 1);
    return query select tap.results_eq(
        'select executed from executed_status',
        'select v.executed from (values (true)) v(executed)',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Execute a test no arguments with two test data records. Expect one call.$scenario$)
    );

    delete from executed_status;
    perform _execute_test(test_id, 1);
    return query select tap.results_eq(
        'select executed from executed_status',
        'select v.executed from (values (true)) v(executed)',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Execute a test no arguments with no test data records. Expect one call.$scenario$)
    );

end;
$$;

COMMIT;
