-- Deploy dream-db-extension-tests:test/functions/_fail_test/return-message to pg

BEGIN;

create function unit_test.test_func_fail_test__return_message()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When failing a test, the function shall return the given message that is indented and commented.
$test_description$;
declare test_id integer;
begin

    -- Create the test
    insert into test ("schema", "function", "description") values ('my_schema', 'my_function', 'my description') returning id into test_id;

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    return query select tap.set_has(
        format($have$select _fail_test(%s, 2, 'fail message')$have$, test_id),
        $want$values ('    # fail message')$want$,
        test_description
    );

end;
$$;

COMMIT;
