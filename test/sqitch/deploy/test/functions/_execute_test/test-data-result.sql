-- Deploy dream-db-extension-tests:test/functions/_execute_test/test-data-result to pg

BEGIN;

create function unit_test.test_func_execute_test__test_data_result()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if the test function takes arguments, and if test data are associated
with the test, then for each test datum, the function shall return an intented formatted result, where
the result name is the schema and function of the test, and the result description contains the test
description, test data description, and test data.
$test_description$;
declare test_id_args integer;
declare actual_result text;
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
        select '';
    end;

    -- Create the test
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function_with_args', 'my description args') returning id into test_id_args;

    -- Create test data
    insert into test_data ("test_id", "description", "parameters") values (test_id_args, 'data description', $params$select '["data"]';$params$);

    -- Plan the tests
    insert into test_plan ("id") values (test_id_args);


    select actual.tap
    from _execute_test(test_id_args, 1) actual(tap)
    where actual.tap like '    ok 1 - pg_temp.my_test_function_with_args%'
    into actual_result
    ;
    return query select tap.matches(
        actual_result,
        'my description args',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Result contains the test description$scenario$)
    );

    return query select tap.matches(
        actual_result,
        'data description',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Result contains the test data description$scenario$)
    );

    return query select tap.matches(
        actual_result,
        '\["data"\]',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Result contains the test data$scenario$)
    );

end;
$$;

COMMIT;
