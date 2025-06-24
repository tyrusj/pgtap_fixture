-- Deploy dream-db-extension-tests:test/functions/_execute_test/no-arguments-reset-pgtap-counter to pg

BEGIN;

create function unit_test.test_func_execute_test__no_arguments_reset_pgtap_counter()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if the test function does not take arguments, before executing the
test, the function shall reset the pgtap test number to 1.
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

    -- Setup pgtap__set to log calls to curr_test
    alter function pgtap__set(text, integer)
    rename to pgtap__set___original;
    create function pgtap__set(text, integer)
    returns integer
    language plpgsql
    as
    $setup$
    begin
        if $1 = 'curr_test' and $2 = 0 then
            insert into calls ("caller", "order") values ('reset_current_test', nextval('call_order'));
        end if;
        return pgtap__set___original($1, $2);
    end;
    $setup$;

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

    -- Create a table to track the order of calls made
    create temp table calls ("caller" text, "order" integer);

    -- Create a sequence to track the order of calls made
    create temp sequence call_order as integer owned by calls."order";


    -- Create a test
    create function pg_temp.my_test_function()
    returns setof text
    language sql
    begin atomic
        insert into calls ("caller", "order") values ('my_test_function', nextval('call_order'));
        select '';
    end;

    -- Add the test
    insert into test ("schema", "function") values ('pg_temp', 'my_test_function') returning id into test_id;

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    perform _execute_test(test_id, 1);
    return query select tap.results_eq(
        'select caller from calls order by "order" asc;',
        $want$values ('reset_current_test'), ('my_test_function')$want$,
        test_description
    );

end;
$$;

COMMIT;
