-- Deploy dream-db-extension-tests:functions/add_test_data/test-must-exist to pg

BEGIN;

create function unit_test.test_func_add_data__test_must_exist()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When adding test data, if no test corresponds with the given schema and function, then the database
shall throw an exception.
$test_description$;
begin

    return query select tap.throws_ok(
        $throws$select add_test_data('my_schema', 'my_function', $data$select '["my_data"]'$data$, 'my description')$throws$,
        null,
        test_description
    );

end;
$$;

COMMIT;
