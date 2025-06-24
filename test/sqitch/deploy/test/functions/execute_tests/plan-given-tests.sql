-- Deploy dream-db-extension-tests:functions/execute_tests/plan-given-tests to pg

BEGIN;

create function unit_test.test_func_execute_tests__plan_given_tests()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, if one or more tests are given, then for each given test, the function shall plan
that test.
$test_description$;
declare test_id_a integer;
declare test_id_b integer;
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

    -- Create tests
    insert into test ("schema", "function") values ('my_schema', 'my_function_a') returning id into test_id_a;
    insert into test ("schema", "function") values ('my_schema', 'my_function_b') returning id into test_id_b;

    -- Execute the scenarios

    perform execute_tests(null::text[], 'my_schema', array['my_function_a']);
    return query select tap.set_eq(
        'select id from test_plan',
        format('values (%s)', test_id_a),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Plan one test.$scenario$)
    );

    delete from test_plan;
    perform execute_tests(null::text[], 'my_schema', array['my_function_a', 'my_function_b']);
    return query select tap.set_eq(
        'select id from test_plan',
        format('values (%s), (%s)', test_id_a, test_id_b),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Plan two tests.$scenario$)
    );

end;
$$;

COMMIT;
