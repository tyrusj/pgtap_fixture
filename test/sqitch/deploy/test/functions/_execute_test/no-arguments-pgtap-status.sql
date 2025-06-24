-- Deploy dream-db-extension-tests:test/functions/_execute_test/no-arguments-pgtap-status to pg

BEGIN;

create function unit_test.test_func_execute_test__no_arguments_pgtap_status()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if the test function does not take arguments, and if all pgtap tests
returned 'ok', then the function shall set the status of the test to 'ok', otherwise the function
shall set the status of the test to 'not ok'.
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
    $mock$
    begin
        if $1 = 'failed' then
            return pgtap__get___original('failed');
        else
            return null;
        end if;
    end;
    $mock$;

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
    create function pg_temp.my_test_function_ok()
    returns setof text
    language plpgsql
    as
    $test$
    begin
        return query select ok(true);
        return query select ok(true);
        return query select ok(true);
    end;
    $test$;

    create function pg_temp.my_test_function_not_ok()
    returns setof text
    language plpgsql
    as
    $test$
    begin
        return query select ok(true);
        return query select ok(false);
        return query select ok(true);
    end;
    $test$;

    -- Create the test
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function_ok', 'my description args') returning id into test_id_ok;
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function_not_ok', 'my description args') returning id into test_id_not_ok;

    -- Plan the tests
    insert into test_plan ("id") values (test_id_ok), (test_id_not_ok);

    perform _execute_test(test_id_ok, 1);
    return query select tap.set_has(
        format('select ok from test_plan where id = %s', test_id_ok),
        'values (true)',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: pgtap tests all ok.$scenario$)
    );

    perform _execute_test(test_id_not_ok, 1);
    return query select tap.set_has(
        format('select ok from test_plan where id = %s', test_id_not_ok),
        'values (false)',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: One pgtap test not ok.$scenario$)
    );

end;
$$;

COMMIT;
