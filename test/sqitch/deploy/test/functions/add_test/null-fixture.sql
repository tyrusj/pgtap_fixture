-- Deploy dream-db-extension-tests:functions/add_test/null-fixture to pg

BEGIN;

create function unit_test.test_func_add_test__null_fixture()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When adding a test, if the given fixture path is null, then the function shall set the fixture ID of the
added test record to null.
$test_description$;
begin

    perform add_test('my_schema', 'my_function', null, null);
    return query select tap.set_eq(
        $set$select parent_fixture_id from test where schema = 'my_schema' and function = 'my_function';$set$,
        $eq$values (null::integer);$eq$,
        test_description
    );

end;
$$;

COMMIT;
