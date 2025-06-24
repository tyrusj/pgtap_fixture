-- Deploy dream-db-extension-tests:functions/add_test_data/create-record to pg

BEGIN;

create function unit_test.test_func_add_data__create_record()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When adding test data, the function shall create a test data record with the given parameters,
description, and a test ID that corresponds with a test record having the given schema and
function.
$test_description$;
declare test_id integer;
begin

    -- Create test
    insert into test ("schema", "function") values ('my_schema', 'my_function') returning id into test_id;

    perform add_test_data('my_schema', 'my_function', $data$select '["my_data"]'$data$, 'my description');
    return query select tap.results_eq(
        $have$select test_id, parameters, description from test_data$have$,
        format($want$values (%s, $data$select '["my_data"]'$data$, 'my description')$want$, test_id),
        test_description
    );

end;
$$;

COMMIT;
