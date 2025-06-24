-- Deploy dream-db-extension-tests:table-test-insert-unique-schema-and-function to pg

BEGIN;

create function unit_test.test_table_test_insert__unique_schema_and_function()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
If a record is added to the test table, and if that record's schema and function match an existing record's
schema and function, then the database shall throw an exception.
$description$;
begin
	-- Insert records into the test table
	insert into test ("schema", "function")
	values ('my_schema_A', 'my_function_A')
	;

	-- Run test scenarios

	return query select tap.lives_ok(
		$test$
			insert into test ("schema", "function")
			values ('my_schema_A', 'my_function_B');
		$test$,
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$1: Insert a record whose schema matches another record and whose function does not match that record's function. Expect no exception.$scenario$
		)
	);

    return query select tap.lives_ok(
		$test$
			insert into test ("schema", "function")
			values ('my_schema_B', 'my_function_A');
		$test$,
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$2: Insert a record whose function matches another record and whose schema does not match that record's schema. Expect no exception.$scenario$
		)
	);

	return query select tap.throws_ok(
		$test$
			insert into test ("schema", "function")
			values ('my_schema_A', 'my_function_A');
		$test$,
		null,
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$3: Insert a record whose function and schema match another record's function and schema. Expect an exception.$scenario$
		)
	);
end;
$$;

COMMIT;
