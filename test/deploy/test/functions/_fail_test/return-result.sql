-- Deploy dream-db-extension-tests:test/functions/_fail_test/return-result to pg

BEGIN;

create function unit_test.test_func_fail_test__return_result()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When failing a test, the function shall return a formatted result, where the result name is the
function schema and name, the result description is the test description, and the result status
is 'not ok'.
$test_description$;
declare test_id integer;
begin

    -- Create the test
    insert into test ("schema", "function", "description") values ('my_schema', 'my_function', 'my description') returning id into test_id;

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    return query select tap.set_has(
        format($have$select _fail_test(%s, 2, 'fail message')$have$, test_id),
        $want$values ('not ok 2 - my_schema.my_function my description')$want$,
        test_description
    );

end;
$$;

COMMIT;
