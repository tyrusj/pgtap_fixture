-- Deploy dream-db-extension-tests:test/functions/_execute_test/return-plan to pg

BEGIN;

create function unit_test.test_func_execute_test__return_plan()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if the test function does take arguments, and if there are test data
associated with the test, then after executing the test function with the test data, the function
shall return an indented formatted test plan where the plan number is the number of test data that
the test function was executed with.
$test_description$;
declare test_id integer;
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

    -- Create a test function
    create function pg_temp.my_test_function_a(parameters jsonb, testDescription text)
    returns setof text
    language plpgsql
    as
    $test$
    begin
        return next '';
    end;
    $test$
    ;

    -- Create a test record
    insert into test ("schema", "function") values ('pg_temp', 'my_test_function_a') returning id into test_id;

    -- Create test data
    insert into test_data ("test_id", "parameters")
    values
        (test_id, $params$select '["value A"]'$params$),
        (test_id, $params$select '["value B"]'$params$),
        (test_id, $params$select '["value C"]'$params$);

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    -- Execute the scenarios

    return query select tap.set_has(
        format('select _execute_test(%s, 1);', test_id),
        $want$values ('    1..3')$want$,
        test_description
    );

end;
$$;

COMMIT;
