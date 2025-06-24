-- Deploy dream-db-extension-tests:test/functions/_execute_text/multiple-functions to pg

BEGIN;

create function unit_test.test_func_execute_test__multiple_functions()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test, if multiple functions are found in the database that have the same name as the
test function, then the function shall fail the test.
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

    -- Create a table that will store whether the test was failed.
    create temp table failed_test(id integer);

    -- Mock _fail_test to check whether it was called.
    alter function _fail_test(test_id integer, num integer, message text)
    rename to _fail_test___original;
    create function _fail_test(test_id integer, num integer, message text)
    returns setof text
    language plpgsql
    as
    $mock$
    begin
        insert into failed_test ("id") values (test_id);
    end;
    $mock$;

    -- Create two test functions with the same name
    create function pg_temp.my_test_function_a()
    returns setof text
    language plpgsql
    as
    $test$
    begin

    end;
    $test$;

    create function pg_temp.my_test_function_a(parameters jsonb, description text)
    returns setof text
    language plpgsql
    as
    $test$
    begin

    end;
    $test$;

    -- Create a test record
    insert into test ("schema", "function") values ('pg_temp', 'my_test_function_a') returning id into test_id;

    -- Plan the test
    insert into test_plan ("id") values (test_id);


    perform _execute_test(test_id, 1);
    return query select tap.results_eq(
        'select id from failed_test',
        format('values (%s)', test_id),
        test_description
    );

end;
$$;

COMMIT;
