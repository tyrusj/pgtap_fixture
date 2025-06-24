-- Deploy dream-db-extension-tests:table-test-update-unique-schema-and-function to pg

BEGIN;

create function unit_test.test_table_test_update__unique_schema_and_function()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
If record is modified in the test table, and if that record's schema and function match an existing record's
schema and function, then the database shall throw an exception.
$description$;
declare id_of_test_to_update integer;
begin
    -- Insert a record in the test table
    insert into test ("schema", "function")
    values ('my_schema_A', 'my_function_A')
    ;

	-- Insert a record in the test table that will be updated
	insert into test ("schema", "function")
	values ('my_schema_B', 'my_function_B')
	returning "id" into id_of_test_to_update
	;

	-- Run test scenarios

	return query select tap.lives_ok(
		format($test$
			update test set ("schema", "function")
			= ('my_schema_A', 'my_function_B')
			where id = %s;
		$test$, id_of_test_to_update),
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$1: Update a record to have a schema that matches an existing record and whose function does not match that record's function. Expect no exception.$scenario$
		)
	);

    return query select tap.lives_ok(
		format($test$
			update test set ("schema", "function")
			= ('my_schema_B', 'my_function_A')
			where id = %s;
		$test$, id_of_test_to_update),
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$2: Update a record to have a function that matches an existing record and whose schema does not match that record's schema. Expect no exception.$scenario$
		)
	);

	return query select tap.throws_ok(
		format($test$
			update test set ("schema", "function")
			= ('my_schema_A', 'my_function_A')
			where id = %s;
		$test$, id_of_test_to_update),
		null,
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$3: Update a record to have a schema and function that match an existing record's schema and function. Expect an exception.$scenario$
		)
	);
end;
$$;

COMMIT;
