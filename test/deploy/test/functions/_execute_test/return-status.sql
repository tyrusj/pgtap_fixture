-- Deploy dream-db-extension-tests:test/functions/_execute_test/return-result to pg

BEGIN;

create function unit_test.test_func_execute_test__return_status()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if the test function takes arguments, and if test data are associated
with the test, and if all executions of the test data returned a status of 'ok', then the function
shall set the status of the test to 'ok', otherwise the function shall set the status of the test to
'not ok'.
$test_description$;
declare test_id_ok integer;
declare test_id_not_ok integer;
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

    -- Create the test functions
    create function pg_temp.my_test_function_ok(jsonb, text)
    returns setof text
    language plpgsql
    as
    $test$
    begin
        return query select ok(true);
    end;
    $test$;

    create function pg_temp.my_test_function_not_ok(parameters jsonb, description text)
    returns setof text
    language plpgsql
    as
    $test$
    begin
        if parameters->>0 = 'f' then
            return query select ok(false);
        else
            return query select ok(true);
        end if;
    end;
    $test$;

    -- Create the test
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function_ok', 'my description args') returning id into test_id_ok;
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function_not_ok', 'my description args') returning id into test_id_not_ok;

    -- Create test data
    insert into test_data ("test_id", "parameters") values (test_id_ok, $params$select '["a"]';$params$);
    insert into test_data ("test_id", "parameters") values (test_id_ok, $params$select '["b"]';$params$);
    insert into test_data ("test_id", "parameters") values (test_id_ok, $params$select '["c"]';$params$);
    insert into test_data ("test_id", "parameters") values (test_id_not_ok, $params$select '["d"]';$params$);
    insert into test_data ("test_id", "parameters") values (test_id_not_ok, $params$select '["e"]';$params$);
    insert into test_data ("test_id", "parameters") values (test_id_not_ok, $params$select '["f"]';$params$);

    -- Plan the tests
    insert into test_plan ("id") values (test_id_ok), (test_id_not_ok);

    perform _execute_test(test_id_ok, 1);
    return query select tap.set_has(
        format('select ok from test_plan where id = %s', test_id_ok),
        'values (true)',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Test data all ok.$scenario$)
    );

    perform _execute_test(test_id_not_ok, 1);
    return query select tap.set_has(
        format('select ok from test_plan where id = %s', test_id_not_ok),
        'values (false)',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: One test datum not ok.$scenario$)
    );

end;
$$;

COMMIT;
