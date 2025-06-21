-- Deploy dream-db-extension-tests:test/functions/_execute_fixture/test-results to pg

BEGIN;

create function unit_test.test_func_execute_fixture__test_results()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture contains tests, then the function shall indent and
return the results of each test.
$test_description$;
declare fixture_id_a integer;
declare test_id_a integer;
declare test_id_b integer;
begin

    -- Setup _execute_test to output specified results
    alter function _execute_test(testId integer, num integer)
    rename to _execute_test___original;
    create function _execute_test(testId integer, num integer)
    returns setof text
    language plpgsql
    as
    $setup$
    declare test_function text;
    begin
        select "function" into test_function
        from test
        where test.id = testId
        ;
        if test_function = 'my_function_a' then
            return next 'test results: my_function_a';
        elsif test_function = 'my_function_b' then
            return next 'test results: my_function_b';
        end if;
    end;
    $setup$;

    -- create fixtures
    insert into fixture ("name") values ('fixture_a') returning id into fixture_id_a;

    -- create tests
    insert into test ("schema", "function", "parent_fixture_id") values ('pg_temp', 'my_function_a', fixture_id_a) returning id into test_id_a;
    insert into test ("schema", "function", "parent_fixture_id") values ('pg_temp', 'my_function_b', fixture_id_a) returning id into test_id_b;

    -- add to plan
    insert into fixture_plan ("id") values (fixture_id_a);
    insert into test_plan ("id") values (test_id_a), (test_id_b);

    return query select tap.set_has(
        format('select _execute_fixture(%s, 1)', fixture_id_a),
        $want$values ('    test results: my_function_a'), ('    test results: my_function_b')$want$,
        test_description
    );

end;
$$;

COMMIT;
