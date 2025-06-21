-- Deploy dream-db-extension-tests:test/functions/_execute_test/wrong-return-type to pg

BEGIN;

create function unit_test.test_func_execute_test__wrong_return_type()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test, if the test function does not return a setof text, then the function shall
fail the test.
$test_description$;
declare test_id_text integer;
declare test_id_setof_integer integer;
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

    -- Create test functions with the wrong type
    create function pg_temp.my_test_function_text()
    returns text
    language plpgsql
    as
    $test$
    begin

    end;
    $test$;

    create function pg_temp.my_test_function_setof_integer()
    returns setof integer
    language plpgsql
    as
    $test$
    begin

    end;
    $test$;

    -- Create test records
    insert into test ("schema", "function") values ('pg_temp', 'my_test_function_text') returning id into test_id_text;
    insert into test ("schema", "function") values ('pg_temp', 'my_test_function_setof_integer') returning id into test_id_setof_integer;

    -- Plan the tests
    insert into test_plan ("id") values (test_id_text), (test_id_setof_integer);


    perform _execute_test(test_id_text, 1);
    return query select tap.results_eq(
        'select id from failed_test',
        format('values (%s)', test_id_text),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Test does not return a set.$scenario$)
    );

    delete from failed_test;
    perform _execute_test(test_id_setof_integer, 1);
    return query select tap.results_eq(
        'select id from failed_test',
        format('values (%s)', test_id_setof_integer),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Test returns a set of the wrong type.$scenario$)
    );

end;
$$;

COMMIT;
