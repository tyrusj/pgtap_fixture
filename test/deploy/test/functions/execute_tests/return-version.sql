-- Deploy dream-db-extension-tests:test/functions/execute_tests/return-version to pg

BEGIN;

create function unit_test.test_func_execute_tests__return_version()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, the function shall return the line 'TAP version 14' before executing
any tests or fixtures.
$test_description$;
begin

    -- Stub _execute_test, so we don't actually execute the test.
    alter function _execute_test(testId integer, num integer)
    rename to _execute_test___original;
    create function _execute_test(testId integer, num integer)
    returns setof text
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

    return query select tap.set_has(
        'select execute_tests(null, null, null)',
        $want$values ('TAP Version 14')$want$,
        test_description
    );

end;
$$;

COMMIT;
