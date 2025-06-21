-- Deploy dream-db-extension-tests:functions/remove_test/remove-unused-fixtures to pg

BEGIN;

create function unit_test.test_func_remove_test__remove_unused_fixtures()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When removing a test, if the test has a parent fixture ID, then the function shall remove unused fixtures
associated with that fixture ID.
$test_description$;
declare parent_fixture_id integer;
declare fixture_id integer;
begin

    -- Add fixtures
    insert into fixture ("name") values ('parent_fixture') returning id into parent_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture', parent_fixture_id) returning id into fixture_id;

    -- Add test
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function', fixture_id);

    perform remove_test('my_schema', 'my_function');
    return query select tap.is_empty(
        'select id from fixture',
        test_description
    );

end;
$$;

COMMIT;
