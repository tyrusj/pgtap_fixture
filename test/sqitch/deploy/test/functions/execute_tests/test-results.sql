-- Deploy dream-db-extension-tests:test/functions/execute_tests/test-results to pg

BEGIN;

create function unit_test.test_func_execute_tests__test_results()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, the function shall return the result of executing each test with no parent fixture.
$test_description$;
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

    -- Mock _execute_test to return simple output
    alter function _execute_test(testId integer, num integer)
    rename to _execute_test___original;
    create function _execute_test(testId integer, num integer)
    returns setof text
    language plpgsql
    as
    $mock$
    begin
        return next 'Test results.';
    end;
    $mock$;

    -- Create a test
    insert into test ("schema", "function") values ('pg_temp', 'my_test_function');

    return query select tap.set_has(
        'select execute_tests(null, null, null)',
        $want$values ('Test results.')$want$,
        test_description
    );

end;
$$;

COMMIT;
