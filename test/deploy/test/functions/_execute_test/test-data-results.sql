-- Deploy dream-db-extension-tests:test/functions/_execute_test/test-data-results to pg

BEGIN;

create function unit_test.test_func_execute_test__test_data_results()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if the test function takes arguments, and if test data are associated
with the test, then for each test datum, the function shall return the twice indented results of
executing the test with that datum.
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

    -- Create the test functions
    create function pg_temp.my_test_function_with_args(jsonb, text)
    returns setof text
    language sql
    begin atomic
        select 'test results';
    end;

    -- Create the test
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function_with_args', 'my description args') returning id into test_id;

    -- Create test data
    insert into test_data ("test_id", "description", "parameters") values (test_id, 'data description', $params$select '["data"]';$params$);

    -- Plan the tests
    insert into test_plan ("id") values (test_id);


    return query select tap.set_has(
        format('select _execute_test(%s, 1)', test_id),
        $want$values ('        test results')$want$,
        test_description
    );

end;
$$;

COMMIT;
