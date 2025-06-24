-- Deploy dream-db-extension-tests:functions/remove_all_test_data/remove-records to pg

BEGIN;

create function unit_test.test_func_remove_all_data__remove_records()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When removing all test data, the function shall remove all test data records whose test ID corresponds
with a test record having the given schema and function.
$test_description$;
declare test_id integer;
declare test_data_id_a integer;
declare test_data_id_b integer;
begin

    -- Create test
    insert into test ("schema", "function") values ('my_schema', 'my_function') returning id into test_id;
    insert into test ("schema", "function") values ('my_schema', 'my_function_no_data');

    -- Create test data
    insert into test_data ("test_id", "parameters", "description") values (test_id, $params$select '["my_data"]'$params$, 'my description') returning id into test_data_id_a;
    insert into test_data ("test_id", "parameters", "description") values (test_id, $params$select '["my_data_b"]'$params$, 'my description b') returning id into test_data_id_b;

    perform remove_all_test_data('my_schema', 'my_function_does_not_exist');
    return query select tap.set_eq(
        $have$select id from test_data$have$,
        format($want$values (%s), (%s)$want$, test_data_id_a, test_data_id_b),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Remove all test data for a test that does not exist. Expect no change.$scenario$)
    );

    perform remove_all_test_data('my_schema', 'my_function_no_data');
    return query select tap.set_eq(
        $have$select id from test_data$have$,
        format($want$values (%s), (%s)$want$, test_data_id_a, test_data_id_b),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Remove all test data for a test that has no test data. Expect no change.$scenario$)
    );

    perform remove_all_test_data('my_schema', 'my_function');
    return query select tap.is_empty(
        $have$select id from test_data$have$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Remove all test data from a test with data. Expect data deleted.$scenario$)
    );

end;
$$;

COMMIT;
