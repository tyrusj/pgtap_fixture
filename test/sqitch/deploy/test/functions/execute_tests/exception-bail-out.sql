-- Deploy dream-db-extension-tests:test/functions/execute_tests/exception-bail-out to pg

BEGIN;

create function unit_test.test_func_execute_tests__exception_bail_out()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, if an exception is thrown, then the function shall return 'Bail Out! Unhandled
exception.'.
$test_description$;
begin

    -- Mock _execute_test to throw an exception
    alter function _execute_test(testId integer, num integer)
    rename to _execute_test___original;
    create function _execute_test(testId integer, num integer)
    returns setof text
    language plpgsql
    as
    $mock$
    begin
        raise 'Test exception.';
    end;
    $mock$;

     -- Stub _plan_child_tests_and_fixtures, since we don't want to plan the child fixtures in this test.
    alter function _plan_child_tests_and_fixtures(fixtureId integer)
    rename to _plan_child_tests_and_fixtures___original;
    create function _plan_child_tests_and_fixtures(fixtureId integer)
    returns void
    language plpgsql
    as
    $stub$
    begin
        
    end;
    $stub$;

    -- Create a test
    insert into test ("schema", "function") values ('my_schema', 'my_function');

    return query select tap.set_has(
        'select execute_tests(null, null, null)',
        $want$values ('Bail Out! Unhandled exception.')$want$,
        test_description
    );

end;
$$;

COMMIT;
