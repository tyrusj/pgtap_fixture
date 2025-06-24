-- Deploy dream-db-extension-tests:test/functions/_execute_test/return-subtest to pg

BEGIN;

create function unit_test.test_func_execute_test__return_subtest()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if the test function does not take arguments, or if the test
function takes arguments and there are test data associated with the test, then the function
shall return a formatted subtest, where the subtest name is the schema and function of the test,
and the subtest description is the test description.
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

    create function pg_temp.my_test_function_no_args()
    returns setof text
    language sql
    begin atomic
        select '';
    end;

    -- Create the test
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function_with_args', 'my description args') returning id into test_id_args;
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function_no_args', 'my description no args') returning id into test_id_no_args;

    -- Create test data
    insert into test_data ("test_id", "parameters") values (test_id_args, $params$select '["data"]';$params$);

    -- Plan the tests
    insert into test_plan ("id") values (test_id_no_args), (test_id_args);

    return query select tap.set_has(
        format('select _execute_test(%s, 1)', test_id_no_args),
        $want$values ('# Subtest: pg_temp.my_test_function_no_args my description no args')$want$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Test with no arguments.$scenario$)
    );

    return query select tap.set_has(
        format('select _execute_test(%s, 1)', test_id_args),
        $want$values ('# Subtest: pg_temp.my_test_function_with_args my description args')$want$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Test with arguments and data.$scenario$)
    );

end;
$$;

COMMIT;
