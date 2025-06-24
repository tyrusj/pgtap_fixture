-- Deploy dream-db-extension-tests:test/functions/_fail_test/test-status to pg

BEGIN;

create function unit_test.test_func_fail_test__test_status()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When failing a test, the function shall set the test's status to 'not ok'.
$test_description$;
declare test_id integer;
begin

    -- Create the test
    insert into test ("schema", "function", "description") values ('my_schema', 'my_function', 'my description') returning id into test_id;

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    perform _fail_test(test_id, 2, 'fail message');

    return query select tap.results_eq(
        format($have$select ok from test_plan where id = %s$have$, test_id),
        $want$values (false)$want$,
        test_description
    );

end;
$$;

COMMIT;
