-- Deploy dream-db-extension-tests:functions/execute_tests/plan-all-tests to pg

BEGIN;

create function unit_test.test_func_execute_tests__plan_all_tests()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, if no fixtures or tests are given, then for each record in the test table that
does not have a parent fixture ID, the function shall plan that test.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_b integer;
declare test_id_with_no_parent_a integer;
declare test_id_with_no_parent_b integer;
declare test_id_with_parent_c integer;
declare test_id_with_parent_d integer;
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

    -- Create fixtures
    insert into fixture ("name") values ('my_fixture_a') returning id into fixture_id_a;
    insert into fixture ("name") values ('my_fixture_b') returning id into fixture_id_b;

    -- Create tests
    insert into test ("schema", "function") values ('my_schema', 'my_function_a') returning id into test_id_with_no_parent_a;
    insert into test ("schema", "function") values ('my_schema', 'my_function_b') returning id into test_id_with_no_parent_b;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_c', fixture_id_a) returning id into test_id_with_parent_c;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_d', fixture_id_b) returning id into test_id_with_parent_d;


    perform execute_tests(null::text[], null::name, null::text[]);
    return query select tap.set_eq(
        'select id from test_plan',
        format('values (%s), (%s)', test_id_with_no_parent_a, test_id_with_no_parent_b),
        test_description
    );

end;
$$;

COMMIT;
