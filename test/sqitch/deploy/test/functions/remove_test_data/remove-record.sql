-- Deploy dream-db-extension-tests:functions/remove_test_data/remove-record to pg

BEGIN;

create function unit_test.test_func_remove_data__remove_record()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When removing test data, the function shall remove the test data record that contains the given
parameters and whose test ID corresponds with a test record having the given schema and function.
$test_description$;
declare test_id integer;
declare test_data_id integer;
begin

    -- Create test
    insert into test ("schema", "function") values ('my_schema', 'my_function') returning id into test_id;

    -- Create test data
    insert into test_data ("test_id", "parameters", "description") values (test_id, $params$select '["my_data"]'$params$, 'my description') returning id into test_data_id;

    perform remove_test_data('my_schema', 'my_function_does_not_exist', $params$select '["my_data"]'$params$);
    return query select tap.results_eq(
        $have$select id from test_data$have$,
        format($want$values (%s)$want$, test_data_id),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Remove test data for a test that does not exist. Expect no change.$scenario$)
    );

    perform remove_test_data('my_schema', 'my_function', $params$select '["my_data does not exist"]'$params$);
    return query select tap.results_eq(
        $have$select id from test_data$have$,
        format($want$values (%s)$want$, test_data_id),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Remove test data that does not exist. Expect no change.$scenario$)
    );

    perform remove_test_data('my_schema', 'my_function', $params$select '["my_data"]'$params$);
    return query select tap.is_empty(
        $have$select id from test_data$have$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Remove test data that exists.$scenario$)
    );

    

end;
$$;

COMMIT;
