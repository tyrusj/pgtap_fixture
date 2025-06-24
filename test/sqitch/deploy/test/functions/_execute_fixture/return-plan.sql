-- Deploy dream-db-extension-tests:test/functions/_execute_fixture/return-plan to pg

BEGIN;

create function unit_test.test_func_execute_fixture__return_plan()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture is not empty, then after executing the fixture, the function
shall return an indented formatted test plan where the plan number is the number of tests and child
fixtures executed in the fixture.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_b integer;
declare fixture_id_c integer;
declare test_id_a integer;
declare test_id_b integer;
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
    insert into fixture ("name", "parent_fixture_id") values ('fixture_b', fixture_id_a) returning id into fixture_id_b;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_c', fixture_id_a) returning id into fixture_id_c;

    -- Create tests
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_a', fixture_id_a) returning id into test_id_a;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_b', fixture_id_a) returning id into test_id_b;

    -- Add to plan
    insert into fixture_plan ("id") values (fixture_id_a), (fixture_id_b), (fixture_id_c);
    insert into test_plan ("id") values (test_id_a), (test_id_b);

    return query select tap.set_has(
        format('select _execute_fixture(%s, 1)', fixture_id_a),
        $want$values ('    1..4')$want$,
        test_description
    );

end;
$$;

COMMIT;
