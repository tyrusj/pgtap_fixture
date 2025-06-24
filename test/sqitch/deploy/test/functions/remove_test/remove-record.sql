-- Deploy dream-db-extension-tests:functions/remove_test/remove-record to pg

BEGIN;

create function unit_test.test_func_remove_test__remove_record()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When removing a test, the function shall remove the record from the test table with the given schema
and function.
$test_description$;
begin

    -- Add test
    insert into test ("schema", "function") values ('my_schema', 'my_function');

    perform remove_test('my_schema', 'my_function');
    return query select tap.is_empty(
        'select id from test',
        test_description
    );

end;
$$;

COMMIT;
