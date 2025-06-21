-- Deploy dream-db-extension-tests:functions/_execute_test/test-must-exist to pg

BEGIN;

create function unit_test.test_func_execute_test__test_must_exist()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if the test id does not exist, then the function shall throw an exception.
$test_description$;
declare test_id_not_exists integer;
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

    -- Add the test to the test table
    insert into test ("schema", "function") values ('pg_temp', 'my_test_function_d') returning id into test_id_not_exists;

    -- Delete the test to ensure that it doesn't exist
    delete from test where id = test_id_not_exists;


    return query select tap.throws_ok(
        format('select _execute_test(%s, 1);', test_id_not_exists),
        null,
        test_description
    );

end;
$$;

COMMIT;
