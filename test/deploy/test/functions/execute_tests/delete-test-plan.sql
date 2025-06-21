-- Deploy dream-db-extension-tests:functions/execute_tests/delete-test-plan to pg

BEGIN;

create function unit_test.test_func_execute_tests__delete_test_plan()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, if a test plan already exists, then the function shall delete that test plan.
$test_description$;
declare test_id_to_delete integer;
declare test_id_to_plan integer;
begin

    -- Stub _execute_test, so that it doesn't actually try to execute the test function.
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

    -- Add tests
    insert into test ("schema", "function") values ('my_schema', 'my_function_to_delete') returning id into test_id_to_delete;
    insert into test ("schema", "function") values ('my_schema', 'my_function_to_plan') returning id into test_id_to_plan;

    -- Add the test to the plan
    insert into test_plan ("id") values (test_id_to_delete);

    perform execute_tests(null::text[], 'my_schema', array['my_function_to_plan']);
    return query select tap.set_hasnt(
        'select id from test_plan',
        format('values (%s)', test_id_to_delete),
        test_description
    );

end;
$$;

COMMIT;
