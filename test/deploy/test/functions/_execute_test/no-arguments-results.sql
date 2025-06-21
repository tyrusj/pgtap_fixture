-- Deploy dream-db-extension-tests:test/functions/_execute_test/no-arguments-result to pg

BEGIN;

create function unit_test.test_func_execute_test__no_arguments_results()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if the test function does not take arguments, then the function shall
return the indented results of the test function.
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

    -- Create the test function
    create function pg_temp.my_test_function()
    returns setof text
    language sql
    begin atomic
        select 'test result';
    end;

    -- Create the test
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function', 'my description') returning id into test_id;

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    return query select tap.set_has(
        format('select _execute_test(%s, 1)', test_id),
        $want$values ('    test result')$want$,
        test_description
    );

end;
$$;

COMMIT;
