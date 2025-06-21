-- Deploy dream-db-extension-tests:table-test-data-update-unique-test-id-role-and-parameters to pg

BEGIN;

create function unit_test.test_table_test_data_update__unique_test_id_role_and_parameters()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
If a record is modified in the test data table, and if a record exists that contains the same test ID
and parameters as an existing record, then the database shall throw an exception.
$description$;
declare existing_test_id_A integer;
declare existing_test_id_B integer;
declare test_data_id_to_update integer;
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

    -- Insert a record that will be updated
    insert into test_data ("test_id", "parameters")
    values (existing_test_id_B, '["param10"]')
    returning id into test_data_id_to_update;

	-- Run test scenarios

    return query select tap.throws_ok(
        format($test$
			update test_data set ("test_id", "parameters")
			= (%s, '["param1"]')
            where id = %s
		$test$, existing_test_id_A, test_data_id_to_update),
		null,
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$1: Update a record to have a test ID and non-null parameters that match an existing record's test ID and parameters. Expect an exception.$scenario$
		)
    );

    return query select tap.throws_ok(
        format($test$
			update test_data set ("test_id", "parameters")
			= (%s, null)
            where id = %s
		$test$, existing_test_id_A, test_data_id_to_update),
		null,
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$2: Update a record to have a test ID and null parameters that match an existing record's test ID and null parameters. Expect an exception.$scenario$
		)
    );

	return query select tap.lives_ok(
		format($test$
			update test_data set ("test_id", "parameters")
			= (%s, '["param2"]')
            where id = %s;
		$test$, existing_test_id_A, test_data_id_to_update),
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$3: Update a record to have a test ID and non-null parameters, where the test ID matches an existing record that has null parameters. Expect no exception.$scenario$
		)
	);

    return query select tap.lives_ok(
		format($test$
			update test_data set ("test_id", "parameters")
			= (%s, '["param1"]')
            where id = %s;
		$test$, existing_test_id_B, test_data_id_to_update),
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$9: Update a record to have a test ID and non-null parameters, where the parameters match an existing record that has a different test ID. Expect no exception.$scenario$
		)
	);
end;
$$;

COMMIT;
