-- Deploy dream-db-extension-tests:test/functions/execute_tests/return-plan to pg

BEGIN;

create function unit_test.test_func_execute_tests__return_plan()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, after executing tests and fixtures, the function shall return a formatted plan,
where the plan number is the number of tests and fixtures that were executed.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_c integer;
begin

    -- Stub _execute_test since we don't want to execute any real test functions
    alter function _execute_test(testId integer, num integer)
    rename to _execute_test___original;
    create function _execute_test(testId integer, num integer)
    returns setof text
    language sql
    as
    $stub$
        select '';
    $stub$;

    -- Create fixtures
    insert into fixture ("name") values ('fixture_a') returning id into fixture_id_a;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_b', fixture_id_a);
    insert into fixture ("name") values ('fixture_c') returning id into fixture_id_c;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_d', fixture_id_c);

    -- Create tests
    insert into test ("schema", "function") values ('my_schema', 'my_function_a');
    insert into test ("schema", "function") values ('my_schema', 'my_function_b');


    return query select tap.set_has(
        'select execute_tests(null, null, null)',
        $want$values ('1..4')$want$,
        test_description
    );

end;
$$;

COMMIT;
