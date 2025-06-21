-- Deploy dream-db-extension-tests:test/functions/_execute_test/increment-test-number to pg

BEGIN;

create function unit_test.test_func_execute_test__increment_test_number()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if the test function takes arguments, and if test data are associated
with the test, then for each test datum, the function shall increment the test number beginning at 1.
$test_description$;
declare test_id_args integer;
declare test_id_no_args integer;
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

    -- Create a table to track which test numbers test has been called with.
    create temp table test_numbers(
        "test_number" integer
    );

    -- Setup _format_result to log the test numbers that have been added to results.
    alter function _format_result(ok boolean, num integer, name text, description text)
    rename to _format_result___original;
    create function _format_result(ok boolean, num integer, name text, description text)
    returns text
    language sql
    begin atomic
        insert into test_numbers ("test_number") values (num);
        select _format_result___original(ok, num, name, description);
    end;

    -- Create the test functions
    create function pg_temp.my_test_function_with_args(jsonb, text)
    returns setof text
    language sql
    begin atomic
        select '';
    end;

    -- Create the test
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function_with_args', 'my description args') returning id into test_id_args;

    -- Create test data
    insert into test_data ("test_id", "parameters") values (test_id_args, $params$select '["data1"]';$params$);
    insert into test_data ("test_id", "parameters") values (test_id_args, $params$select '["data2"]';$params$);
    insert into test_data ("test_id", "parameters") values (test_id_args, $params$select '["data3"]';$params$);
    insert into test_data ("test_id", "parameters") values (test_id_args, $params$select '["data4"]';$params$);

    -- Plan the tests
    insert into test_plan ("id") values (test_id_args);

    perform _execute_test(test_id_args, 100);
    return query select tap.set_has(
        'select test_number from test_numbers',
        'values (1), (2), (3), (4)',
        test_description
    );

end;
$$;

COMMIT;
