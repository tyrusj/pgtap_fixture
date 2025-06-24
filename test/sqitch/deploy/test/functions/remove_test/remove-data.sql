-- Deploy dream-db-extension-tests:functions/remove_test/remove-data to pg

BEGIN;

create function unit_test.test_func_remove_test__remove_data()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When removing a test, if the test has associated test data, then the function shall remove those test data.
$test_description$;
declare test_id integer;
begin

    -- Add test
    insert into test ("schema", "function") values ('my_schema', 'my_function') returning id into test_id;

    -- Add test data
    insert into test_data ("test_id", "parameters", "description") values (test_id, $data$select '["my data"]'$data$, 'my description');
    insert into test_data ("test_id", "parameters", "description") values (test_id, $data$select '["my data 2"]'$data$, 'my description 2');

    perform remove_test('my_schema', 'my_function');
    return query select tap.is_empty(
        'select id from test_data',
        test_description
    );

end;
$$;

COMMIT;
