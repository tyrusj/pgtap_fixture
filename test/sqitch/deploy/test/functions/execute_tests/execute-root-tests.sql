-- Deploy dream-db-extension-tests:functions/execute_tests/execute-root-tests to pg

BEGIN;

create function unit_test.test_func_execute_tests__execute_root_tests()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, for each test in the plan that does not have a parent fixture, the function shall
execute that test with its test data.
$test_description$;
declare test_id_a integer;
declare test_id_b integer;
declare test_id_non_root_c integer;
declare fixture_id_c integer;
begin

    -- Mock _execute_test to track which tests are executed.
    alter function _execute_test(testId integer, num integer)
    rename to _execute_test___original;
    create function _execute_test(testId integer, num integer)
    returns setof text
    language plpgsql
    as
    $mock$
    begin
        insert into executed_test ("id") values (testId);
    end;
    $mock$;

    -- Create a table to track which tests are executed.
    create temp table executed_test (id integer);

    -- Create a fixture
    insert into fixture ("name") values ('my_fixture') returning id into fixture_id_c;

    -- Create tests
    insert into test ("schema", "function") values ('my_schema', 'my_function_a') returning id into test_id_a;
    insert into test ("schema", "function") values ('my_schema', 'my_function_b') returning id into test_id_b;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_c', fixture_id_c);

    -- Execute the scenarios

    perform execute_tests(null::text[], 'my_schema', array['my_function_a', 'my_function_b', 'my_function_c']);
    return query select tap.set_eq(
        'select id from executed_test',
        format('values (%s), (%s)', test_id_a, test_id_b),
        test_description
    );

end;
$$;

COMMIT;
