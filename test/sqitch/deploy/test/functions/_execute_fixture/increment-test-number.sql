-- Deploy dream-db-extension-tests:test/functions/_execute_fixture/increment-test-number to pg

BEGIN;

create function unit_test.test_func_execute_fixture__increment_test_number()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture is not empty, then for each test and child fixture, the
function shall increment the test number beginning at 1.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_b integer;
declare fixture_id_c integer;
declare test_id_a integer;
declare test_id_b integer;
begin

    -- Create a table to track which test numbers tests and fixtures have been called with.
    create temp table test_numbers(
        "test_number" integer
    );

    -- Stub _function_rollback, so that changes to the test_numbers table stay after executing _execute_fixture
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

    -- Setup the _execute_fixture to log what values it was called with
    alter function _execute_fixture(fixtureId integer, num integer)
    rename to _execute_fixture___original;
    create function _execute_fixture(fixtureId integer, num integer)
    returns setof text
    language plpgsql
    as
    $setup$
    begin
        insert into test_numbers ("test_number")
        values (num);
        return query select _execute_fixture___original(fixtureId, num);
    end;
    $setup$;

    -- Mock _execute_test to log what values it was called with
    alter function _execute_test(testId integer, num integer)
    rename to _execute_test___original;
    create function _execute_test(testId integer, num integer)
    returns setof text
    language sql
    as
    $mock$
        insert into test_numbers ("test_number")
        values (num);
        select '';
    $mock$;

    -- Create fixtures
    insert into fixture ("name") values ('fixture_a') returning id into fixture_id_a;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_b', fixture_id_a) returning id into fixture_id_b;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_c', fixture_id_a) returning id into fixture_id_c;

    -- Create tests
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_a', fixture_id_a) returning id into test_id_a;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_b', fixture_id_a) returning id into test_id_b;

    -- Add to plan
    insert into fixture_plan ("id") values (fixture_id_a), (fixture_id_b), (fixture_id_c);
    insert into test_plan ("id") values (test_id_a), (test_id_b);

    perform _execute_fixture(fixture_id_a, 100);
    return query select tap.set_eq(
        'select test_number from test_numbers',
        'values (1), (2), (3), (4), (100)',
        test_description
    );

end;
$$;

COMMIT;
