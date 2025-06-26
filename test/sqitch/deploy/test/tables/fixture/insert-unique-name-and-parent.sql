-- Deploy dream-db-extension-tests:table-fixture-insert-unique-name-and-parent to pg

BEGIN;

create function unit_test.test_table_fixture_insert__unique_name_and_parent()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
If a record is added to the fixture table, and if that record's name and parent fixture ID are the same as an existing record's 
parent and fixture ID, then the database shall throw an exception.
$description$;
declare id_of_fixture_with_no_parent integer;
declare id_of_fixture_with_parent_A integer;
declare id_of_fixture_with_parent_B integer;
begin
    -- Insert a record in the fixture table with no parent ID
    insert into fixture
        ("name", "parent_fixture_id")
    values
		('top_level_fixture_A', null)
	returning "id" into id_of_fixture_with_no_parent
    ;

	-- Insert a record in the fixture table with a parent ID
	insert into fixture
		("name", "parent_fixture_id")
	values
		('child_fixture_A', id_of_fixture_with_no_parent)
	returning "id" into id_of_fixture_with_parent_A
	;

	-- Insert another record in the fixture table with a parent ID
	insert into fixture
		("name", "parent_fixture_id")
	values
		('child_fixture_B', id_of_fixture_with_no_parent)
	returning "id" into id_of_fixture_with_parent_B
	;

	-- Run test scenarios

	return query select tap.lives_ok(
		format($test$
			insert into fixture ("name", "parent_fixture_id")
			values ('NOT_child_fixture_A', %s);
		$test$, id_of_fixture_with_parent_A),
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$1: Insert a record whose parent ID is not null and whose name does not match the name on the existing record with that parent ID. Expect no exception.$scenario$
		)
	);

	return query select tap.throws_ok(
		format($test$
			insert into fixture ("name", "parent_fixture_id")
			values ('child_fixture_A', %s);
		$test$, id_of_fixture_with_no_parent),
		null,
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$2: Insert a record whose parent ID is not null and whose name matches the name on the existing record with that parent ID. Expect exception.$scenario$
		)
	);

	return query select tap.lives_ok(
		$test$
		insert into fixture ("name", "parent_fixture_id")
		values ('NOT_top_level_fixture_A', null);
		$test$,
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$3: Insert a record whose parent ID is null and whose name does not match the name on the existing record with a null parent ID. Expect no exception.$scenario$
		)
	);

	return query select tap.throws_ok(
		$test$
		insert into fixture ("name", "parent_fixture_id")
		values ('top_level_fixture_A', null);
		$test$,
		null,
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$4: Insert a record whose parent ID is null and whose name matches the name on the existing record with a null parent ID. Expect exception.$scenario$
		)
	);

	return query select tap.lives_ok(
		format($test$
			insert into fixture ("name", "parent_fixture_id")
			values ('top_level_fixture_A', %s);
		$test$, id_of_fixture_with_parent_A),
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$5: Insert a record whose parent ID is not null and whose name matches the name on an existing record whose parent ID is null. Expect no exception.$scenario$
		)
	);

	return query select tap.lives_ok(
		format($test$
			insert into fixture ("name", "parent_fixture_id")
			values ('child_fixture_B', %s);
		$test$, id_of_fixture_with_parent_A),
		format(
			E'%s\ntest_scenario: %s', test_description,
			$scenario$6: Insert a record whose parent ID is not null and whose name matches the name on an existing record with a different non-null parent ID. Expect no exception.$scenario$
		)
	);
end;
$$;

COMMIT;
