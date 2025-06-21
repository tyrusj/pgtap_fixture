-- Deploy dream-db-extension-tests:functions/_execute_test/execute-with-parameters to pg

BEGIN;

create function unit_test.test_func_execute_test__execute_with_parameters()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, for each record in the test data table that corresponds with the given
test, the database shall execute the test function with the result of executing the test data record's
parameters statement.
$test_description$;
declare test_id integer;
declare parameters_A text := $param$select '["stringA", 7]'$param$;
declare parameters_B text := $param$select '["stringB", 17]'$param$;
declare parameters_C text := $param$select '["stringC", 27]'$param$;
declare debug_var record;
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

    -- Create a table where the parameters that a test is executed with will be stored.
    create temp table executed_parameters(parameters jsonb);

    -- Create a test function
    create function pg_temp.my_test_function_a(parameters jsonb, testDescription text)
    returns setof text
    language plpgsql
    as
    $test$
    begin
        insert into executed_parameters ("parameters") values (parameters);
    end;
    $test$
    ;

    -- Create a test record
    insert into test ("schema", "function") values ('pg_temp', 'my_test_function_a') returning id into test_id;

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    -- Execute the scenarios

    delete from test_data;
    delete from executed_parameters;
    insert into test_data ("test_id", "parameters") values (test_id, parameters_A);
    perform _execute_test(test_id, 1);
    return query select tap.set_has(
        'select parameters from executed_parameters',
        $has$select '["stringA", 7]'::jsonb$has$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Execute with one data set. Expect the test to be executed with the data set.$scenario$)
    );

    delete from test_data;
    delete from executed_parameters;
    insert into test_data ("test_id", "parameters") values (test_id, parameters_B), (test_id, parameters_C);
    perform _execute_test(test_id, 1);
    return query select tap.set_has(
        'select parameters from executed_parameters',
        format('select v.parameters from (values (%L::jsonb), (%L::jsonb)) v(parameters)', '["stringB", 17]', '["stringC", 27]'),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Execute with two data sets. Expect the test to be executed with both data sets.$scenario$)
    );

end;
$$;

COMMIT;
