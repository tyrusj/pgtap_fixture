-- Deploy dream-db-extension-tests:functions/add_test/add-record to pg

BEGIN;

create function unit_test.test_func_add_test__add_record()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When adding a test, the function shall add a record to the test table with the given schema, function,
and description.
$test_description$;
begin

    perform add_test('my_schema', 'my_function', 'my_description');
    return query select tap.set_eq(
        $set$
            select true from test
            where
                schema = 'my_schema'
                and function = 'my_function'
                and description = 'my_description'
            ;
        $set$,
        $eq$values (true);$eq$,
        test_description
    );

end;
$$;

COMMIT;
