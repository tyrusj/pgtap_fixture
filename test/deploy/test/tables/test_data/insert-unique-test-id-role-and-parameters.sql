-- Deploy dream-db-extension-tests:table-test-data-insert-unique-test-id-role-and-parameters to pg

BEGIN;

create function unit_test.test_table_test_data_insert__unique_test_id_role_and_parameters()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
If a record is added to the test data table, and if a record exists that contains the same test ID and
parameters as an existing record, then the database shall throw an exception.
$description$;
declare existing_test_id_A integer;
declare existing_test_id_B integer;
begin
    -- Add a test for the test data to reference.
    insert into test ("schema", "function")
    values ('my_schema_A', 'my_function_A')
    returning id into existing_test_id_A
    ;
    insert into test ("schema", "function")
    values ('my_schema_B', 'my_function_B')
    returning id into existing_test_id_B
    ;

	-- Insert records into the test data table
	insert into test_data ("test_id", "parameters")
	values
        (existing_test_id_A, '["param1"]'),
        (existing_test_id_A, null)
	;

	-- Run test scenarios

    return query select tap.throws_ok(
        format($test$
			insert into test_data ("test_id", "parameters")
			values (%s, '["param1"]')
		$test$, existing_test_id_A),
		null,
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$1: Insert a record with a test ID and non-null parameters that match an existing record's test ID and parameters. Expect an exception.$scenario$
		)
    );

    return query select tap.throws_ok(
        format($test$
			insert into test_data ("test_id", "parameters")
			values (%s, null)
		$test$, existing_test_id_A),
		null,
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$2: Insert a record with a test ID and null parameters that match an existing record's test ID and null parameters. Expect an exception.$scenario$
		)
    );

	return query select tap.lives_ok(
		format($test$
			insert into test_data ("test_id", "parameters")
			values (%s, '["param2"]');
		$test$, existing_test_id_A),
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$3: Insert a record with a test ID and non-null parameters, where the test ID matches an existing record that has null parameters. Expect no exception.$scenario$
		)
	);

    return query select tap.lives_ok(
		format($test$
			insert into test_data ("test_id", "parameters")
			values (%s, '["param1"]');
		$test$, existing_test_id_B),
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$4: Insert a record with a test ID and non-null parameters, where the parameters match an existing record that has a different test ID. Expect no exception.$scenario$
		)
	);
end;
$$;

COMMIT;
