-- Deploy dream-db-extension-tests:test/functions/execute_tests/fixture-results to pg

BEGIN;

create function unit_test.test_func_execute_tests__fixture_results()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, the function shall return the result of executing each fixture with no parent fixture.
$test_description$;
begin

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

    -- Mock _execute_fixture to return simple results.
    alter function _execute_fixture(fixtureId integer, num integer)
    rename to _execute_fixture___original;
    create function _execute_fixture(fixtureId integer, num integer)
    returns setof text
    language plpgsql
    as
    $mock$
    begin
        return next 'Fixture results.';
    end;
    $mock$;

    -- Create a fixture
    insert into fixture ("name") values ('my_fixture');

    return query select tap.set_has(
        'select execute_tests(null, null, null)',
        $want$values ('Fixture results.')$want$,
        test_description
    );

end;
$$;

COMMIT;
