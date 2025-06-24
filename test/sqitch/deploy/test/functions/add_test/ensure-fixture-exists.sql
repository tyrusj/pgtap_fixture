-- Deploy dream-db-extension-tests:functions/add_test/ensure-fixture-exists to pg

BEGIN;

create function unit_test.test_func_add_test__ensure_fixture_exists()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When adding a test, if the given fixture path is not null, then the function shall ensure that the fixture
that corresponds with the given fixture path exists.
$test_description$;
begin

    -- Mock the function _get_fixture_by_path_and_root to ensure that it is called with the option to
    -- create the fixture path.
    alter function _get_fixture_by_path_and_root(
        fixturePath text,
        root integer,
        createMissingFixtures boolean
    )
    rename to _get_fixture_by_path_and_root___original;
    create function _get_fixture_by_path_and_root(
        fixturePath text,
        root integer,
        createMissingFixtures boolean default false
    )
    returns integer
    language plpgsql
    as
    $mock$
    begin
        insert into function_called ("fixturePath", "root", "createMissingFixtures")
        values (fixturePath, root, createMissingFixtures)
        ;
        return _get_fixture_by_path_and_root___original(fixturePath, root, createMissingFixtures);
    end;
    $mock$;

    -- Create table to track whether _get_fixture_by_path_and_root was called
    create temp table function_called ("fixturePath" text, root integer, "createMissingFixtures" boolean);

    -- Ensure that _get_fixture_by_path_and_root was called with the option to create the fixture path set to
    -- true.
    perform add_test('my_schema', 'my_function', 'my_description', 'path/to/fixture');
    return query select tap.results_eq(
        $have$select * from function_called$have$,
        $want$values ('path/to/fixture', null::integer, true)$want$,
        test_description
    );

end;
$$;

COMMIT;
