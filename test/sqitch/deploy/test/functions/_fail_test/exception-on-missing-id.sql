-- Deploy dream-db-extension-tests:test/functions/_fail_test/exception-on-missing-id to pg

BEGIN;

create function unit_test.test_func_fail_test__exception_on_missing_id()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When failing a test, if the given test ID does not exist, then the function shall throw an exception.
$test_description$;
declare test_id integer;
begin

    -- Create the test
    insert into test ("schema", "function", "description") values ('my_schema', 'my_function', 'my description') returning id into test_id;

    -- Delete the test to ensure that it doesn't exist
    delete from test where id = test_id;

    return query select tap.throws_ok(
        format($throws$select _fail_test(%s, 2, 'fail message')$throws$, test_id),
        null,
        test_description
    );

end;
$$;

COMMIT;
