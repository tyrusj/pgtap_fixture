-- Deploy dream-db-extension-tests:test/functions/_execute_fixture/return-status to pg

BEGIN;

create function unit_test.test_func_execute_fixture__return_status()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture is not empty, and if all tests and child fixtures returned
a status of 'ok', then the function shall set the fixture status to 'ok', otherwise the function
shall set the fixture status to 'not ok'.
$test_description$;
declare fixture_id_ok_a integer;
declare fixture_id_ok_b integer;
declare fixture_id_ok_c integer;
declare fixture_id_not_ok_d integer;
declare fixture_id_ok_e integer;
declare fixture_id_ok_f integer;
declare fixture_id_not_ok_g integer;
declare fixture_id_not_ok_h integer;
declare fixture_id_ok_i integer;
declare test_id_ok_a integer;
declare test_id_ok_b integer;
declare test_id_ok_c integer;
declare test_id_not_ok_d integer;
declare test_id_ok_e integer;
declare test_id_not_ok_f integer;
begin

    -- Mock _execute_test to only set the status on the tests
    alter function _execute_test(testId integer, num integer)
    rename to _execute_test___original;
    create function _execute_test(testId integer, num integer)
    returns setof text
    language plpgsql
    as
    $mock$
    declare test_function text;
    begin
        select "function" into test_function
        from test where id = testId
        ;
        if array[test_function] <@ array['test_function_not_ok_d', 'test_function_not_ok_f'] then
            update test_plan set ok = false where id = testId;
        else
            update test_plan set ok = true where id = testId;
        end if;
    end;
    $mock$;

    -- Create fixtures
    insert into fixture ("name") values ('fixture_ok_a') returning id into fixture_id_ok_a;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_ok_b', fixture_id_ok_a) returning id into fixture_id_ok_b;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_ok_c', fixture_id_ok_a) returning id into fixture_id_ok_c;
    insert into fixture ("name") values ('fixture_not_ok_d') returning id into fixture_id_not_ok_d;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_ok_e', fixture_id_not_ok_d) returning id into fixture_id_ok_e;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_ok_f', fixture_id_not_ok_d) returning id into fixture_id_ok_f;
    insert into fixture ("name") values ('fixture_not_ok_g') returning id into fixture_id_not_ok_g;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_not_ok_h', fixture_id_not_ok_g) returning id into fixture_id_not_ok_h;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_ok_i', fixture_id_not_ok_g) returning id into fixture_id_ok_i;

    -- Create tests
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'test_function_ok_a', fixture_id_ok_a) returning id into test_id_ok_a;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'test_function_ok_b', fixture_id_ok_a) returning id into test_id_ok_b;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'test_function_ok_c', fixture_id_not_ok_d) returning id into test_id_ok_c;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'test_function_not_ok_d', fixture_id_not_ok_d) returning id into test_id_not_ok_d;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'test_function_ok_e', fixture_id_not_ok_g) returning id into test_id_ok_e;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'test_function_not_ok_f', fixture_id_not_ok_h) returning id into test_id_not_ok_f;

    -- Add the tests and fixtures to the plan
    insert into fixture_plan ("id") values (fixture_id_ok_a), (fixture_id_ok_b), (fixture_id_ok_c);
    insert into test_plan ("id") values (test_id_ok_a), (test_id_ok_b);

    perform _execute_fixture(fixture_id_ok_a, 1);
    return query select tap.results_eq(
        format('select ok from fixture_plan where id = %s', fixture_id_ok_a),
        $want$values (true)$want$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: All tests and fixtures ok. Expect ok.$scenario$)
    );

    delete from fixture_plan;
    delete from test_plan;
    insert into fixture_plan ("id") values (fixture_id_not_ok_d), (fixture_id_ok_e), (fixture_id_ok_f);
    insert into test_plan ("id") values (test_id_ok_c), (test_id_not_ok_d);
    perform _execute_fixture(fixture_id_not_ok_d, 1);
    return query select tap.results_eq(
        format('select ok from fixture_plan where id = %s', fixture_id_not_ok_d),
        $want$values (false)$want$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: One test not ok. Expect not ok.$scenario$)
    );

    delete from fixture_plan;
    delete from test_plan;
    insert into fixture_plan ("id") values (fixture_id_not_ok_g), (fixture_id_not_ok_h), (fixture_id_ok_i);
    insert into test_plan ("id") values (test_id_ok_e), (test_id_not_ok_f);
    perform _execute_fixture(fixture_id_not_ok_g, 1);
    return query select tap.results_eq(
        format('select ok from fixture_plan where id = %s', fixture_id_not_ok_g),
        $want$values (false)$want$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: One fixture not ok. Expect not ok.$scenario$)
    );

end;
$$;

COMMIT;
