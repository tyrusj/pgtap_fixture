-- Deploy dream-db-extension-tests:test/functions/_fail_test/return-subtest to pg

BEGIN;

create function unit_test.test_func_fail_test__return_subtest()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When failing a test, the function shall return a formatted subtest, where the subtest name is the
function schema and name, and the subtest description is the test description.
$test_description$;
declare test_id integer;
begin

    -- Create the test
    insert into test ("schema", "function", "description") values ('my_schema', 'my_function', 'my description') returning id into test_id;

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    return query select tap.set_has(
        format($have$select _fail_test(%s, 2, 'fail message')$have$, test_id),
        $want$values ('# Subtest: my_schema.my_function my description')$want$,
        test_description
    );

end;
$$;

COMMIT;
