-- Deploy dream-db-extension-tests:test/functions/_execute_test/no-arguments-skip to pg

BEGIN;

create function unit_test.test_func_execute_test__no_arguments_skip()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if the test function takes arguments, and if no test data are associated
with the test, then the function shall return a formatted skipped test, where the name is the function
schema and name, the description is the test description, and the reason is 'No test data.'.
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
    create function pg_temp.my_test_function(jsonb, text)
    returns setof text
    language sql
    begin atomic
        select '';
    end;

    -- Create the test
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function', 'my description') returning id into test_id;

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    return query select tap.set_has(
        format('select _execute_test(%s, 1)', test_id),
        $want$values ('ok 1 - pg_temp.my_test_function my description # skip No test data.')$want$,
        test_description
    );

end;
$$;

COMMIT;
